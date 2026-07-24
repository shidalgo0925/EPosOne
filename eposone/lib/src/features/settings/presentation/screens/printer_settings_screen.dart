import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:eposone/src/core/printing/network_printer_service.dart';
import 'package:eposone/src/core/printing/printer_prefs.dart';
import 'package:eposone/src/core/printing/thermal_printer_service.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';

/// Configurar impresora térmica: Bluetooth o Red (TCP ESC/POS).
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<BluetoothInfo> _devices = [];
  String? _selectedMac;
  String? _selectedName;
  PrinterChannel _channel = PrinterChannel.bluetooth;
  bool _openDrawer = false;
  bool _printLogoOnThermal = false;
  bool _loading = true;
  bool _busy = false;

  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '${PrinterPrefs.defaultNetworkPort}');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _channel = await PrinterPrefs.getChannel();
    _selectedMac = await PrinterPrefs.getPrinterMac();
    _selectedName = await PrinterPrefs.getPrinterName();
    _openDrawer = await PrinterPrefs.getOpenCashDrawerOnCash();
    _printLogoOnThermal = await PrinterPrefs.getPrintLogoOnThermal();
    _hostCtrl.text = await PrinterPrefs.getNetworkHost() ?? '';
    _portCtrl.text = '${await PrinterPrefs.getNetworkPort()}';

    if (Platform.isAndroid || Platform.isIOS) {
      final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      if (granted) {
        _devices = await ThermalPrinterService.listPairedDevices();
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setChannel(PrinterChannel channel) async {
    await PrinterPrefs.setChannel(channel);
    setState(() => _channel = channel);
  }

  Future<void> _saveDevice(BluetoothInfo device) async {
    await PrinterPrefs.savePrinter(mac: device.macAdress, name: device.name);
    await _setChannel(PrinterChannel.bluetooth);
    setState(() {
      _selectedMac = device.macAdress;
      _selectedName = device.name;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impresora BT: ${device.name}')),
      );
    }
  }

  Future<void> _saveNetwork() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la IP de la impresora')),
      );
      return;
    }
    final port = int.tryParse(_portCtrl.text.trim()) ??
        PrinterPrefs.defaultNetworkPort;
    if (port < 1 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puerto inválido (1–65535)')),
      );
      return;
    }
    await PrinterPrefs.saveNetworkPrinter(host: host, port: port);
    await _setChannel(PrinterChannel.network);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impresora de red: $host:$port')),
      );
    }
  }

  Future<void> _testPrint() async {
    setState(() => _busy = true);
    bool ok;
    if (_channel == PrinterChannel.network) {
      final host = _hostCtrl.text.trim();
      final port = int.tryParse(_portCtrl.text.trim()) ??
          PrinterPrefs.defaultNetworkPort;
      if (host.isNotEmpty) {
        await PrinterPrefs.saveNetworkPrinter(host: host, port: port);
      }
      ok = await NetworkPrinterService.testPrint(host: host, port: port);
    } else {
      ok = await ThermalPrinterService.printLines([
        'EPOSOne',
        'Prueba Bluetooth',
        DateTime.now().toString().substring(0, 16),
        'OK ESC/POS BT',
      ]);
    }
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Impresión de prueba enviada'
                : _channel == PrinterChannel.network
                    ? 'No se pudo conectar. Revisa IP, puerto y Wi‑Fi.'
                    : 'No se pudo imprimir. Verifica emparejamiento BT.',
          ),
          backgroundColor: ok ? null : Colors.red,
        ),
      );
    }
  }

  bool get _canTest {
    if (_busy) return false;
    if (_channel == PrinterChannel.network) {
      return _hostCtrl.text.trim().isNotEmpty;
    }
    return _selectedMac != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impresora')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Canal de impresión',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<PrinterChannel>(
                  segments: const [
                    ButtonSegment(
                      value: PrinterChannel.bluetooth,
                      label: Text('Bluetooth'),
                      icon: Icon(Icons.bluetooth),
                    ),
                    ButtonSegment(
                      value: PrinterChannel.network,
                      label: Text('Red'),
                      icon: Icon(Icons.wifi),
                    ),
                  ],
                  selected: {_channel},
                  onSelectionChanged: (s) => _setChannel(s.first),
                ),
                const SizedBox(height: 8),
                Text(
                  _channel == PrinterChannel.network
                      ? 'Imprime directo por IP (ESC/POS TCP). Sin diálogo PDF.'
                      : 'Imprime por Bluetooth emparejado. Sin diálogo PDF.',
                  style: const TextStyle(
                      fontSize: 12, color: EposBrand.textSecondary),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Abrir cajón en venta efectivo'),
                  subtitle: const Text(
                      'Requiere impresora con cajón (kick) conectado'),
                  value: _openDrawer,
                  onChanged: (v) async {
                    await PrinterPrefs.setOpenCashDrawerOnCash(v);
                    setState(() => _openDrawer = v);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Logo en impresora térmica'),
                  subtitle: const Text(
                    'Imprime el logo del negocio arriba del recibo (raster). '
                    'Configúralo en Ajustes → Negocio.',
                  ),
                  value: _printLogoOnThermal,
                  onChanged: (v) async {
                    await PrinterPrefs.setPrintLogoOnThermal(v);
                    setState(() => _printLogoOnThermal = v);
                  },
                ),
                const Divider(height: 32),
                if (_channel == PrinterChannel.network)
                  _buildNetworkSection()
                else
                  _buildBluetoothSection(),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _canTest ? _testPrint : null,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_outlined),
                  label: const Text('Imprimir prueba'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Si el canal falla, Imprimir abre el PDF del sistema como respaldo.',
                  style: TextStyle(fontSize: 12, color: EposBrand.textSecondary),
                ),
              ],
            ),
    );
  }

  Widget _buildNetworkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Impresora de red',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _hostCtrl,
          decoration: const InputDecoration(
            labelText: 'IP o hostname',
            hintText: '192.168.1.50',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lan),
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _portCtrl,
          decoration: const InputDecoration(
            labelText: 'Puerto',
            hintText: '9100',
            border: OutlineInputBorder(),
            helperText: 'Raw TCP ESC/POS — casi siempre 9100',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _saveNetwork,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar red'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Quitar IP',
              onPressed: () async {
                await PrinterPrefs.clearNetworkPrinter();
                _hostCtrl.clear();
                _portCtrl.text = '${PrinterPrefs.defaultNetworkPort}';
                setState(() {});
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBluetoothSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        const Text(
          'Impresoras emparejadas (Bluetooth)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (!Platform.isAndroid && !Platform.isIOS)
          const Text('Bluetooth disponible en Android/iOS.')
        else if (_devices.isEmpty)
          const Text(
            'No hay dispositivos BT emparejados. Empareja la impresora en Ajustes del sistema.',
          )
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
      ],
    );
  }
}
