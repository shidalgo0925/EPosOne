import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/features/platform/domain/onboarding_session.dart';

/// P0.20 — Deep link desde EN1 (Gate1 / QR Contract V1).
///
/// - `eposone://provision?code=<CODE>`
/// - `https://…/eposone/install?code=<CODE>`
///
/// Solo extrae `code` → Connect (Register). No pide modo/org/plan.
class En1DeepLinkBinder extends StatefulWidget {
  const En1DeepLinkBinder({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<En1DeepLinkBinder> createState() => _En1DeepLinkBinderState();
}

class _En1DeepLinkBinderState extends State<En1DeepLinkBinder> {
  StreamSubscription<Uri>? _sub;
  final _appLinks = AppLinks();
  String? _lastCode;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _route(initial);
    } catch (e) {
      debugPrint('[EN1 DeepLink] initial: $e');
    }
    _sub = _appLinks.uriLinkStream.listen(
      _route,
      onError: (Object e) => debugPrint('[EN1 DeepLink] stream: $e'),
    );
  }

  void _route(Uri uri) {
    // ADR-035: transporte de activación.
    if (uri.path.toLowerCase().contains('activate') ||
        uri.host.toLowerCase() == 'activate') {
      final token = uri.queryParameters['token']?.trim();
      if (token != null && token.isNotEmpty) {
        if (_lastCode == 'act:$token') return;
        _lastCode = 'act:$token';
        widget.router.go(
          '/platform/activate?token=${Uri.encodeComponent(token)}',
        );
        return;
      }
    }

    final code = extractProvisioningCodeFromScan(uri.toString());
    if (code == null || code.isEmpty) {
      debugPrint('[EN1 DeepLink] ignorado: $uri');
      return;
    }
    if (_lastCode == code) return;
    _lastCode = code;
    // Preferir activate si parece token largo.
    if (code.length >= 20) {
      widget.router.go(
        '/platform/activate?token=${Uri.encodeComponent(code)}',
      );
      return;
    }
    widget.router.go('/platform/connect?code=${Uri.encodeComponent(code)}');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
