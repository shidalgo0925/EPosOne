import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/platform/data/installation_lifecycle.dart';

/// Gate ADR-014: si falta bootstrap/ready, cierra sesión y fuerza `/platform/bootstrap`.
Future<bool> ensureInstallationReadyForPos(
  WidgetRef ref,
  BuildContext context,
) async {
  if (!await InstallationLifecycle.requiresBlockingBootstrap()) {
    return true;
  }
  ref.read(posSessionProvider.notifier).logout();
  if (context.mounted) {
    context.go('/platform/bootstrap');
  }
  return false;
}
