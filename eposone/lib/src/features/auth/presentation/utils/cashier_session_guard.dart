import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eposone/src/core/session/pos_session.dart';
import 'package:eposone/src/features/platform/data/en1_cashier_catalog_store.dart';

/// Si el cajero EN1 de la sesión quedó inactivo tras sync, fuerza re-login.
Future<bool> enforceActiveEn1CashierSession(
  WidgetRef ref, {
  BuildContext? context,
  String? message,
}) async {
  final session = ref.read(posSessionProvider);
  final contactId = session?.cashierContactId;
  if (contactId == null) return true;

  final active = await En1CashierCatalogStore.isContactActive(contactId);
  if (active) return true;

  ref.read(posSessionProvider.notifier).lock();
  if (context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ??
              'Este cajero fue desactivado en EN1. Selecciona otro cajero.',
        ),
        backgroundColor: Colors.orange.shade800,
      ),
    );
    context.go('/pin');
  }
  return false;
}
