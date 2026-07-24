import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:eposone/src/core/printing/production_destination.dart';
import 'package:eposone/src/core/printing/production_print_service.dart';
import 'package:eposone/src/core/printing/thermal_printer_service.dart';
import 'package:eposone/src/core/theme/eposone_theme.dart';

/// Lista de destinos de producción (Cocina / Bar / …).
class ProductionDestinationsScreen extends StatefulWidget {
  const ProductionDestinationsScreen({super.key});

  @override
  State<ProductionDestinationsScreen> createState() =>
      _ProductionDestinationsScreenState();
}

class _ProductionDestinationsScreenState
    extends State<ProductionDestinationsScreen> {
  List<ProductionDestination> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ProductionDestinationStore.list();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Producción (Cocina / Bar)'),
        actions: [
          TextButton(
            onPressed: () => context.push('/settings/production/routing'),
            child: const Text('Routing'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/settings/production/edit');
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Agrega destinos: Cocina, Bar, Bar Terraza…\n'
                      'Cada uno puede ser impresora (BT/red) o pantalla (reservada).',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = _items[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          d.isScreen
                              ? Icons.tv
                              : d.channel == ProductionChannel.network
                                  ? Icons.wifi
                                  : Icons.bluetooth,
                          color: d.active ? EposBrand.orange : Colors.grey,
                        ),
                        title: Text(d.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${d.areaLabel} · ${d.channelLabel}'
                          '${d.channel == ProductionChannel.network && d.host != null ? ' · ${d.host}:${d.port}' : ''}'
                          '${d.channel == ProductionChannel.bluetooth && d.btName != null ? ' · ${d.btName}' : ''}'
                          '${!d.active ? ' · inactivo' : ''}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await context
                              .push('/settings/production/edit?id=${d.id}');
                          _load();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

/// Crear / editar un destino.
class ProductionDestinationEditScreen extends StatefulWidget {
  final String? destinationId;
  const ProductionDestinationEditScreen({super.key, this.destinationId});

  @override
  State<ProductionDestinationEditScreen> createState() =>
      _ProductionDestinationEditScreenState();
}

class _ProductionDestinationEditScreenState
    extends State<ProductionDestinationEditScreen> {
  final _nameCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '9100');
  ProductionArea _area = ProductionArea.kitchen;
  ProductionChannel _channel = ProductionChannel.network;
  String? _id;
  String? _btMac;
  String? _btName;
  bool _active = true;
  bool _loading = true;
  bool _busy = false;
  List<BluetoothInfo> _devices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.destinationId != null) {
      final d = await ProductionDestinationStore.getById(widget.destinationId!);
      if (d != null) {
        _id = d.id;
        _nameCtrl.text = d.name;
        _area = d.area;
        _channel = d.channel;
        _btMac = d.btMac;
        _btName = d.btName;
        _hostCtrl.text = d.host ?? '';
        _portCtrl.text = '${d.port}';
        _active = d.active;
      }
    }
    if (Platform.isAndroid || Platform.isIOS) {
      final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      if (granted) {
        _devices = await ThermalPrinterService.listPairedDevices();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre requerido')),
      );
      return;
    }
    final port = int.tryParse(_portCtrl.text.trim()) ?? 9100;
    var dest = _id == null
        ? ProductionDestination.create(
            name: name, area: _area, channel: _channel)
        : ProductionDestination(
            id: _id!,
            name: name,
            area: _area,
            channel: _channel,
            btMac: _btMac,
            btName: _btName,
            host: _hostCtrl.text.trim().isEmpty ? null : _hostCtrl.text.trim(),
            port: port,
            active: _active,
          );
    if (_id != null) {
      dest = dest.copyWith(
        name: name,
        area: _area,
        channel: _channel,
        btMac: _btMac,
        btName: _btName,
        host: _hostCtrl.text.trim().isEmpty ? null : _hostCtrl.text.trim(),
        port: port,
        active: _active,
      );
    } else {
      dest = ProductionDestination(
        id: dest.id,
        name: name,
        area: _area,
        channel: _channel,
        btMac: _btMac,
        btName: _btName,
        host: _hostCtrl.text.trim().isEmpty ? null : _hostCtrl.text.trim(),
        port: port,
        active: _active,
      );
    }
    await ProductionDestinationStore.upsert(dest);
    if (mounted) context.pop();
  }

  Future<void> _test() async {
    setState(() => _busy = true);
    final port = int.tryParse(_portCtrl.text.trim()) ?? 9100;
    final dest = ProductionDestination(
      id: _id ?? 'test',
      name: _nameCtrl.text.trim().isEmpty ? 'Prueba' : _nameCtrl.text.trim(),
      area: _area,
      channel: _channel,
      btMac: _btMac,
      btName: _btName,
      host: _hostCtrl.text.trim(),
      port: port,
      active: true,
    );
    if (dest.isScreen) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pantalla reservada — KDS en una fase posterior'),
        ),
      );
      return;
    }
    final ok = await ProductionPrintService.testDestination(dest);
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Comanda de prueba enviada' : 'Falló la prueba'),
          backgroundColor: ok ? null : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_id == null ? 'Nuevo destino' : 'Editar destino'),
        actions: [
          if (_id != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ProductionDestinationStore.delete(_id!);
                if (mounted) context.pop();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Cocina, Bar, Bar Terraza…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProductionArea>(
                  initialValue: _area,
                  decoration: const InputDecoration(
                    labelText: 'Área',
                    border: OutlineInputBorder(),
                  ),
                  items: ProductionArea.values
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(a == ProductionArea.kitchen
                                ? 'Cocina'
                                : a == ProductionArea.bar
                                    ? 'Bar'
                                    : 'Otro'),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _area = v ?? ProductionArea.kitchen),
                ),
                const SizedBox(height: 12),
                const Text('Canal', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<ProductionChannel>(
                  segments: const [
                    ButtonSegment(
                      value: ProductionChannel.network,
                      label: Text('Red'),
                      icon: Icon(Icons.wifi),
                    ),
                    ButtonSegment(
                      value: ProductionChannel.bluetooth,
                      label: Text('BT'),
                      icon: Icon(Icons.bluetooth),
                    ),
                    ButtonSegment(
                      value: ProductionChannel.screen,
                      label: Text('Pantalla'),
                      icon: Icon(Icons.tv),
                    ),
                  ],
                  selected: {_channel},
                  onSelectionChanged: (s) =>
                      setState(() => _channel = s.first),
                ),
                const SizedBox(height: 16),
                if (_channel == ProductionChannel.network) ...[
                  TextField(
                    controller: _hostCtrl,
                    decoration: const InputDecoration(
                      labelText: 'IP',
                      hintText: '192.168.1.25',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Puerto',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
                if (_channel == ProductionChannel.bluetooth) ...[
                  if (_btMac != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_btName ?? 'BT'),
                      subtitle: Text(_btMac!),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _btMac = null;
                          _btName = null;
                        }),
                      ),
                    ),
                  if (_devices.isEmpty)
                    const Text('Empareja la impresora en Ajustes del sistema.')
                  else
                    for (final d in _devices)
                      ListTile(
                        title: Text(d.name),
                        subtitle: Text(d.macAdress),
                        trailing: _btMac == d.macAdress
                            ? const Icon(Icons.check, color: EposBrand.orange)
                            : null,
                        onTap: () => setState(() {
                          _btMac = d.macAdress;
                          _btName = d.name;
                        }),
                      ),
                ],
                if (_channel == ProductionChannel.screen)
                  const Text(
                    'Pantalla se aprovisiona ahora. KDS (bump, estados) llega en una fase posterior. Al guardar pedido no imprimirá papel.',
                    style: TextStyle(color: EposBrand.textSecondary, fontSize: 13),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy || _channel == ProductionChannel.screen
                      ? null
                      : _test,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_outlined),
                  label: const Text('Imprimir prueba'),
                ),
              ],
            ),
    );
  }
}
