import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/features/operations_control/application/occ_pulse_provider.dart';
import 'package:eposone/src/features/operations_control/presentation/occ_alerts_tab.dart';
import 'package:eposone/src/features/operations_control/presentation/occ_audit_tab.dart';
import 'package:eposone/src/features/operations_control/presentation/occ_cash_tab.dart';
import 'package:eposone/src/features/operations_control/presentation/occ_hoy_tab.dart';
import 'package:eposone/src/features/operations_control/presentation/occ_operation_tab.dart';
import 'package:eposone/src/features/operations_control/presentation/occ_payments_tab.dart';

/// OCC shell — ADR-016 Fase A (superficie operacional, no reportes).
class OperationsControlShell extends ConsumerStatefulWidget {
  const OperationsControlShell({super.key});

  @override
  ConsumerState<OperationsControlShell> createState() =>
      _OperationsControlShellState();
}

class _OperationsControlShellState
    extends ConsumerState<OperationsControlShell> {
  int _index = 0;

  static const _destinations = [
    (Icons.today_outlined, 'Hoy'),
    (Icons.monitor_heart_outlined, 'Operación'),
    (Icons.point_of_sale_outlined, 'Cajas'),
    (Icons.payments_outlined, 'Pagos'),
    (Icons.notification_important_outlined, 'Alertas'),
    (Icons.history_edu_outlined, 'Auditoría'),
  ];

  @override
  Widget build(BuildContext context) {
    final pulse = ref.watch(occPulseProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final attention = pulse.asData?.value.attentionCount ?? 0;

    final body = IndexedStack(
      index: _index,
      children: const [
        OccHoyTab(),
        OccOperationTab(),
        OccCashTab(),
        OccPaymentsTab(),
        OccAlertsTab(),
        OccAuditTab(),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Control'),
        actions: [
          if (attention > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.orange.shade100,
                  label: Text('$attention atención'),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(occPulseProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: EposBrand.surface,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.$1),
                        label: Text(d.$2),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.$1),
                    label: d.$2,
                  ),
              ],
            ),
    );
  }
}
