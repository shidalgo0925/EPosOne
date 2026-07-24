import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:eposone/src/core/printing/print_engine.dart';
import 'package:eposone/src/core/printing/thermal_ops_text.dart';
import 'package:eposone/src/core/providers/business_config_provider.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/sales/data/repositories/sale_repository.dart';
import 'package:eposone/src/features/sales/domain/entities/sale.dart';

/// Reportes → Empleados (cajeros) y Productos — ventas del período.
class EmployeesReportScreen extends ConsumerStatefulWidget {
  const EmployeesReportScreen({super.key});

  @override
  ConsumerState<EmployeesReportScreen> createState() =>
      _EmployeesReportScreenState();
}

class _EmployeesReportScreenState extends ConsumerState<EmployeesReportScreen> {
  late DateTime _from;
  late DateTime _to;
  Map<String, _Agg> _byCashier = {};
  Map<String, _Agg> _byProduct = {};
  bool _loading = true;
  bool _showProducts = false;

  @override
  void initState() {
    super.initState();
    final local = En1DateTimeService.toBusinessLocal(En1DateTimeService.nowUtc());
    _from = DateTime(local.year, local.month, local.day);
    _to = _from.add(const Duration(days: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final loc =
        En1DateTimeService.toBusinessLocal(En1DateTimeService.nowUtc()).location;
    final fromUtc =
        tz.TZDateTime(loc, _from.year, _from.month, _from.day).toUtc();
    final toUtc = tz.TZDateTime(loc, _to.year, _to.month, _to.day).toUtc();
    final repo = ref.read(saleRepositoryProvider);
    final sales = await repo.getAllSales(from: fromUtc, to: toUtc);
    final completed =
        sales.where((s) => s.status == SaleStatus.completed).toList();

    final byCashier = <String, _Agg>{};
    final byProduct = <String, _Agg>{};

    for (final s in completed) {
      final key = s.cashierName ?? s.cashierId ?? 'Sin cajero';
      byCashier.putIfAbsent(key, () => _Agg(key));
      byCashier[key]!.tickets++;
      byCashier[key]!.total += s.total;

      final items = await repo.getSaleItems(s.localId);
      for (final it in items) {
        byProduct.putIfAbsent(it.productName, () => _Agg(it.productName));
        byProduct[it.productName]!.tickets += it.quantity.round();
        byProduct[it.productName]!.total += it.total;
      }
    }

    if (!mounted) return;
    setState(() {
      _byCashier = byCashier;
      _byProduct = byProduct;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(businessConfigProvider);
    final symbol = config?.currencySymbol ?? 'B/.';
    final map = _showProducts ? _byProduct : _byCashier;
    final sorted = map.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return Scaffold(
      appBar: AppBar(
        title: Text(_showProducts ? 'Productos' : 'Empleados'),
        actions: [
          IconButton(
            tooltip: 'Hoy',
            onPressed: () {
              final local =
                  En1DateTimeService.toBusinessLocal(En1DateTimeService.nowUtc());
              setState(() {
                _from = DateTime(local.year, local.month, local.day);
                _to = _from.add(const Duration(days: 1));
              });
              _load();
            },
            icon: const Icon(Icons.today),
          ),
          TextButton(
            onPressed: () => setState(() => _showProducts = !_showProducts),
            child: Text(_showProducts ? 'Cajeros' : 'Productos'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      En1DateTimeService.formatLocal(
                        tz.TZDateTime(
                          En1DateTimeService.toBusinessLocal(
                                  En1DateTimeService.nowUtc())
                              .location,
                          _from.year,
                          _from.month,
                          _from.day,
                        ).toUtc(),
                        'dd/MM/yyyy',
                      ),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: EposBrand.navy),
                    ),
                  ),
                ),
                Expanded(
                  child: sorted.isEmpty
                      ? const Center(child: Text('Sin datos en el período'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sorted.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final a = sorted[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(a.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(_showProducts
                                  ? '${a.tickets} uds'
                                  : '${a.tickets} tickets'),
                              trailing: Text(
                                '$symbol${a.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: EposBrand.navy),
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: FilledButton.icon(
                      onPressed: sorted.isEmpty
                          ? null
                          : () {
                              final title = _showProducts
                                  ? 'VENTAS POR PRODUCTO'
                                  : 'VENTAS POR CAJERO';
                              final lines = <String>[
                                ThermalOpsText.center(title),
                                ThermalOpsText.center(
                                    config?.businessName ?? 'EPOSOne'),
                                ThermalOpsText.line(),
                                for (final a in sorted.take(40))
                                  ThermalOpsText.row(
                                    ThermalOpsText.clip(a.name, 24),
                                    '$symbol${a.total.toStringAsFixed(2)}',
                                  ),
                                ThermalOpsText.line(),
                              ];
                              PrintEngine.printDocument(
                                context: context,
                                textLines: lines,
                                buildPdf: (format) =>
                                    ThermalOpsText.linesToPdf(lines,
                                        pageFormat: format),
                                thermalOkMessage: 'Reporte enviado',
                              );
                            },
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Agg {
  final String name;
  int tickets = 0;
  double total = 0;
  _Agg(this.name);
}
