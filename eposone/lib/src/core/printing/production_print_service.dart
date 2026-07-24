import 'dart:io';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:eposone/src/core/printing/esc_pos_bytes.dart';
import 'package:eposone/src/core/printing/kitchen_ticket_builder.dart';
import 'package:eposone/src/core/printing/network_printer_service.dart';
import 'package:eposone/src/core/printing/production_destination.dart';
import 'package:eposone/src/core/printing/production_routing_store.dart';
import 'package:eposone/src/features/pos/presentation/providers/cart_provider.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Resultado de un intento de impresión de producción.
class ProductionPrintResult {
  final String destinationName;
  final ProductionChannel channel;
  final bool printed;
  final bool screenSkipped;
  final String? error;

  const ProductionPrintResult({
    required this.destinationName,
    required this.channel,
    this.printed = false,
    this.screenSkipped = false,
    this.error,
  });
}

/// Agrupa líneas del carrito por destino e imprime Kitchen Tickets.
class ProductionPrintService {
  /// Imprime comandas al guardar pedido. No usa la impresora de caja.
  static Future<List<ProductionPrintResult>> printFromCart({
    required BusinessConfig? config,
    required CartState cart,
    String? orderLabel,
    String? comment,
    String? customerName,
  }) async {
    if (cart.items.isEmpty) return const [];

    final destinations = await ProductionDestinationStore.list();
    final byId = {for (final d in destinations) d.id: d};

    final grouped = <String, List<KitchenTicketLine>>{};

    for (final item in cart.items) {
      final destId = await ProductionRoutingStore.resolveDestinationId(
        productId: item.product.localId,
        categoryId: item.product.categoryId,
      );
      if (destId == null) continue;
      final dest = byId[destId];
      if (dest == null || !dest.active) continue;

      grouped.putIfAbsent(destId, () => []).add(
            KitchenTicketLine(
              productName: item.product.name,
              quantity: item.quantity,
              modifiers: item.modifiers,
            ),
          );
    }

    if (grouped.isEmpty) return const [];

    final results = <ProductionPrintResult>[];
    for (final entry in grouped.entries) {
      final dest = byId[entry.key]!;
      final lines = KitchenTicketBuilder.build(
        config: config,
        destinationName: dest.name,
        lines: entry.value,
        orderLabel: orderLabel,
        comment: comment,
        orderType: cart.orderType,
        customerName: customerName,
      );

      if (dest.isScreen) {
        results.add(ProductionPrintResult(
          destinationName: dest.name,
          channel: dest.channel,
          screenSkipped: true,
        ));
        continue;
      }

      final ok = await _printToDestination(dest, lines);
      results.add(ProductionPrintResult(
        destinationName: dest.name,
        channel: dest.channel,
        printed: ok,
        error: ok ? null : 'No se pudo imprimir',
      ));
    }
    return results;
  }

  static Future<bool> testDestination(ProductionDestination dest) async {
    final lines = KitchenTicketBuilder.build(
      config: null,
      destinationName: dest.name,
      lines: const [
        KitchenTicketLine(productName: 'PRUEBA COMANDA', quantity: 1),
      ],
      orderLabel: 'TEST',
    );
    if (dest.isScreen) return false;
    return _printToDestination(dest, lines);
  }

  static Future<bool> _printToDestination(
    ProductionDestination dest,
    List<String> lines,
  ) async {
    final bytes = EscPosBytes.fromLines(lines);
    switch (dest.channel) {
      case ProductionChannel.network:
        final host = dest.host?.trim();
        if (host == null || host.isEmpty) return false;
        return NetworkPrinterService.sendRaw(
          bytes,
          host: host,
          port: dest.port,
        );
      case ProductionChannel.bluetooth:
        return _printBluetooth(dest.btMac, bytes);
      case ProductionChannel.screen:
        return false;
    }
  }

  static Future<bool> _printBluetooth(String? mac, List<int> bytes) async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    if (mac == null || mac.isEmpty) return false;
    try {
      final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      if (!granted) return false;
      final connected =
          await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (!connected) return false;
      return PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    }
  }
}
