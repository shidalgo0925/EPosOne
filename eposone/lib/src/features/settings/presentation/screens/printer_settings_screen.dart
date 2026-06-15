import 'dart:io';

import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:eposone/src/core/printing/printer_prefs.dart';
import 'package:eposone/src/core/printing/thermal_printer_service.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';

/// L5.1 — Configurar impresora térmica Bluetooth.
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<BluetoothInfo> _devices = [];
  String? _selectedMac;
  String? _selectedName;
  bool _openDrawer = false;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _selectedMac = await PrinterPrefs.getPrinterMac();
    _selectedName = await PrinterPrefs.getPrinterName();
    _openDrawer = await PrinterPrefs.getOpenCashDrawerOnCash();

    if (Platform.isAndroid || Platform.isIOS) {
      final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      if (granted) {
        _devices = await ThermalPrinterService.listPairedDevices();
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveDevice(BluetoothInfo device) async {
    await PrinterPrefs.savePrinter(mac: device.macAdress, name: device.name);
    setState(() {
      _selectedMac = device.macAdress;
      _selectedName = device.name;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impresora: ${device.name}')),
      );
    }
  }

  Future<void> _testPrint() async {
    setState(() => _busy = true);
    final ok = await ThermalPrinterService.testPrint();
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Impresión de prueba enviada' : 'No se pudo imprimir. Verifica emparejamiento BT.'),
          backgroundColor: ok ? null : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impresora térmica')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_selectedMac != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.print, color: EposBrand.orange),
                      title: Text(_selectedName ?? 'Impresora'),
                      subtitle: Text(_selectedMac!),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () async {
                          await PrinterPrefs.clearPrinter();
                          setState(() {
                            _selectedMac = null;
                            _selectedName = null;
                          });
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Abrir cajón en venta efectivo'),
                  subtitle: const Text('Requiere impresora con cajón conectado (L5.3)'),
                  value: _openDrawer,
                  onChanged: (v) async {
                    await PrinterPrefs.setOpenCashDrawerOnCash(v);
                    setState(() => _openDrawer = v);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Impresoras emparejadas (Bluetooth)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (!Platform.isAndroid && !Platform.isIOS)
                  const Text('Impresión térmica BT disponible en Android/iOS.')
                else if (_devices.isEmpty)
                  const Text('No hay dispositivos BT emparejados. Empareja la impresora en Ajustes del sistema.')
                else
                  for (final d in _devices)
                    Card(
                      child: ListTile(
                        title: Text(d.name),
                        subtitle: Text(d.macAdress),
                        trailing: _selectedMac == d.macAdress
                            ? const Icon(Icons.check, color: EposBrand.orange)
                            : null,
                        onTap: () => _saveDevice(d),
                      ),
                    ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _busy || _selectedMac == null ? null : _testPrint,
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.print_outlined),
                  label: const Text('Imprimir prueba'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar lista'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Si no hay impresora BT, el botón Imprimir usa el diálogo del sistema (PDF 80mm).',
                  style: TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                ),
              ],
            ),
    );
  }
}
