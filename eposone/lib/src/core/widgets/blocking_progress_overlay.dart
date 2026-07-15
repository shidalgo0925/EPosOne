import 'package:flutter/material.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';

/// Overlay bloqueante para operaciones importantes (Hito 3B.1 UX).
class BlockingProgressOverlay {
  BlockingProgressOverlay._();

  static Future<T> run<T>({
    required BuildContext context,
    required String message,
    required Future<T> Function() action,
    String completedMessage = '✓ Operación completada',
    bool showCompletedFlash = true,
  }) async {
    final nav = Navigator.of(context, rootNavigator: true);
    var closed = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: EposBrand.orange),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: EposBrand.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final result = await action();
      if (nav.canPop() && !closed) {
        nav.pop();
        closed = true;
      }
      if (showCompletedFlash && context.mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                completedMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: EposBrand.navy,
                ),
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
      return result;
    } catch (e) {
      if (nav.canPop() && !closed) {
        nav.pop();
        closed = true;
      }
      rethrow;
    }
  }
}
