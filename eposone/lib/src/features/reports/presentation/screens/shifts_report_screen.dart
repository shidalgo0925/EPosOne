import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eposone/src/core/printing/print_engine.dart';
import 'package:eposone/src/core/printing/thermal_ops_text.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';
import 'package:eposone/src/features/cash_register/presentation/providers/cash_register_provider.dart';

/// Reportes → Caja / Turnos (consulta → imprimir).
class ShiftsReportScreen extends ConsumerWidget {
  const ShiftsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(cashRegisterHistoryProvider);
    final config = ref.watch(businessConfigProvider);
    final symbol = config?.currencySymbol ?? 'B/.';

    return Scaffold(
      appBar: AppBar(title: const Text('Caja / Turnos')),
      body: history.when(
        data: (regs) {
          if (regs.isEmpty) {
            return const Center(child: Text('Sin turnos registrados'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: regs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = regs[i];
                    final open = r.status == CashRegisterStatus.open;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          open ? Icons.lock_open : Icons.lock,
                          color: open ? Colors.green : EposBrand.navy,
                        ),
                        title: Text(
                          open ? 'Turno abierto' : 'Turno cerrado',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Abrió ${En1DateTimeService.formatLocal(r.openDate)}'
                          '${r.closeDate != null ? '\nCerró ${En1DateTimeService.formatLocal(r.closeDate!)}' : ''}'
                          '${r.openedBy != null ? '\n${r.openedBy}' : ''}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          '$symbol${r.openingAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FilledButton.icon(
                    onPressed: () {
                      final lines = <String>[
                        ThermalOpsText.center('TURNOS DE CAJA'),
                        ThermalOpsText.center(
                            config?.businessName ?? 'EPOSOne'),
                        ThermalOpsText.line(),
                        for (final r in regs.take(30)) ...[
                          r.status == CashRegisterStatus.open
                              ? 'ABIERTO'
                              : 'CERRADO',
                          'Ini: ${En1DateTimeService.formatLocal(r.openDate)}',
                          if (r.closeDate != null)
                            'Fin: ${En1DateTimeService.formatLocal(r.closeDate!)}',
                          if (r.openedBy != null) 'Por: ${r.openedBy}',
                          ThermalOpsText.row('Fondo',
                              '$symbol${r.openingAmount.toStringAsFixed(2)}'),
                          if (r.closingAmount != null)
                            ThermalOpsText.row('Cierre',
                                '$symbol${r.closingAmount!.toStringAsFixed(2)}'),
                          if (r.difference != null)
                            ThermalOpsText.row('Diferencia',
                                '$symbol${r.difference!.toStringAsFixed(2)}'),
                          ThermalOpsText.line(),
                        ],
                      ];
                      PrintEngine.printDocument(
                        context: context,
                        textLines: lines,
                        buildPdf: (format) => ThermalOpsText.linesToPdf(lines,
                            pageFormat: format),
                        thermalOkMessage: 'Reporte de turnos enviado',
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Imprimir'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
