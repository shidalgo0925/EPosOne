import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/features/platform/data/activation_claims_store.dart';
import 'package:eposone/src/features/platform/domain/onboarding_session.dart';

/// Deep links EN1:
/// - Activación Standalone (ADR-035): `…/activate?token=` · `eposone://activate?token=`
/// - Provision Connected (explícito): `eposone://provision?code=` · install?code=
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
    final token = extractActivationToken(uri.toString());
    if (token != null && token.isNotEmpty) {
      if (_lastCode == 'act:$token') return;
      _lastCode = 'act:$token';
      widget.router.go(
        '/platform/activate?token=${Uri.encodeComponent(token)}',
      );
      return;
    }

    final code = extractProvisioningCodeFromScan(uri.toString());
    if (code == null || code.isEmpty) {
      debugPrint('[EN1 DeepLink] ignorado: $uri');
      return;
    }
    final lower = uri.toString().toLowerCase();
    if (!lower.contains('provision') && uri.host.toLowerCase() != 'provision') {
      debugPrint('[EN1 DeepLink] no es provision ni activate: $uri');
      return;
    }
    if (_lastCode == code) return;
    _lastCode = code;
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
