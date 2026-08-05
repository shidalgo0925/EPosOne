import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/utils/pin_hash.dart';
import 'package:eposone/src/features/auth/data/repositories/cashier_repository.dart';
import 'package:eposone/src/features/auth/domain/entities/cashier.dart';
import 'package:eposone/src/features/platform/data/en1_cashier_catalog_store.dart';

class DiscountAuthPinResult {
  const DiscountAuthPinResult({
    required this.authorizedByUserId,
    required this.authorizedByName,
  });

  final String authorizedByUserId;
  final String authorizedByName;
}

/// PIN gate for Discount Domain programs with [requiresAuthorization].
Future<DiscountAuthPinResult?> showDiscountAuthorizePinDialog(
  BuildContext context,
  WidgetRef ref, {
  String title = 'Autorizar descuento',
}) {
  return showDialog<DiscountAuthPinResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DiscountAuthorizePinDialog(title: title),
  );
}

class _Candidate {
  const _Candidate.local(this.local) : en1 = null;
  const _Candidate.en1(this.en1) : local = null;

  final Cashier? local;
  final En1CashierLocal? en1;

  String get id =>
      local?.localId ?? 'en1_${en1!.cashierContactId}';

  String get name {
    if (local != null) {
      final role = local!.role == CashierRole.admin ? 'Admin' : 'Cajero';
      return '${local!.name} ($role)';
    }
    return en1!.cashierName;
  }
}

class _DiscountAuthorizePinDialog extends ConsumerStatefulWidget {
  const _DiscountAuthorizePinDialog({required this.title});

  final String title;

  @override
  ConsumerState<_DiscountAuthorizePinDialog> createState() =>
      _DiscountAuthorizePinDialogState();
}

class _DiscountAuthorizePinDialogState
    extends ConsumerState<_DiscountAuthorizePinDialog> {
  final _pinCtrl = TextEditingController();
  List<_Candidate> _candidates = const [];
  _Candidate? _selected;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final locals =
        await ref.read(cashierRepositoryProvider).getActiveCashiers();
    locals.sort((a, b) {
      if (a.role != b.role) {
        return a.role == CashierRole.admin ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
    final en1 = await En1CashierCatalogStore.listActiveWithVerifiers();
    final list = <_Candidate>[
      for (final c in locals) _Candidate.local(c),
      for (final c in en1)
        if (c.pinVerifier != null && c.pinVerifier!.isNotEmpty)
          _Candidate.en1(c),
    ];
    if (!mounted) return;
    setState(() {
      _candidates = list;
      _selected = list.isEmpty ? null : list.first;
      _loading = false;
      if (list.isEmpty) {
        _error = 'No hay cajeros con PIN para autorizar';
      }
    });
  }

  Future<void> _submit() async {
    final sel = _selected;
    final pin = _pinCtrl.text.trim();
    if (sel == null) return;
    if (pin.length < 4) {
      setState(() => _error = 'PIN incompleto');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var ok = false;
      if (sel.local != null) {
        ok = await PinVerifier.verify(pin, sel.local!.pinHash);
      } else if (sel.en1 != null) {
        ok = await En1CashierCatalogStore.verifyPin(
          cashierContactId: sel.en1!.cashierContactId,
          pin: pin,
        );
      }
      if (!ok) {
        setState(() {
          _error = 'PIN incorrecto';
          _pinCtrl.clear();
          _busy = false;
        });
        return;
      }
      if (!mounted) return;
      Navigator.pop(
        context,
        DiscountAuthPinResult(
          authorizedByUserId: sel.id,
          authorizedByName: sel.local?.name ?? sel.en1!.cashierName,
        ),
      );
    } catch (e) {
      setState(() {
        _error = '$e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: _loading
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<_Candidate>(
                    initialValue: _selected,
                    decoration: const InputDecoration(
                      labelText: 'Autoriza',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final c in _candidates)
                        DropdownMenuItem(value: c, child: Text(c.name)),
                    ],
                    onChanged: _busy
                        ? null
                        : (v) => setState(() {
                              _selected = v;
                              _error = null;
                            }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinCtrl,
                    obscureText: true,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _busy || _selected == null ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Autorizar'),
        ),
      ],
    );
  }
}
