import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:eposone/src/core/printing/thermal_ops_text.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_movement.dart';
import 'package:eposone/src/features/cash_register/domain/entities/cash_register.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Documentos de caja: apertura y movimiento — ancho operativo 42.
class CashDocumentBuilder {
  static List<String> buildOpenText({
    required BusinessConfig? config,
    required CashRegister register,
    required String symbol,
  }) {
    return [
      ThermalOpsText.center('APERTURA DE CAJA'),
      ThermalOpsText.center(config?.businessName ?? 'EPOSOne'),
      ThermalOpsText.line(),
      'Fecha: ${En1DateTimeService.formatLocal(register.openDate)}',
      if (register.openedBy != null) 'Abrio: ${register.openedBy}',
      if (register.currentCashierName != null)
        'Cajero: ${register.currentCashierName}',
      ThermalOpsText.row('Fondo inicial',
          '$symbol${register.openingAmount.toStringAsFixed(2)}'),
      if (register.notes != null && register.notes!.isNotEmpty)
        'Notas: ${register.notes}',
      ThermalOpsText.line(),
    ];
  }

  static List<String> buildMovementText({
    required BusinessConfig? config,
    required CashMovement movement,
    required String symbol,
  }) {
    final out = movement.isOutflow;
    return [
      ThermalOpsText.center(out ? 'RETIRO / SALIDA' : 'INGRESO / ENTRADA'),
      ThermalOpsText.center(config?.businessName ?? 'EPOSOne'),
      ThermalOpsText.line(),
      'Fecha: ${En1DateTimeService.formatLocal(movement.movementDate)}',
      'Tipo: ${cashMovementTypeLabel(movement.type)}',
      'Motivo: ${movement.reason}',
      if (movement.cashierName != null) 'Cajero: ${movement.cashierName}',
      ThermalOpsText.row('Monto',
          '${out ? '-' : '+'}$symbol${movement.amount.abs().toStringAsFixed(2)}'),
      if (movement.notes != null && movement.notes!.isNotEmpty)
        'Notas: ${movement.notes}',
      ThermalOpsText.line(),
    ];
  }

  static Future<Uint8List> buildOpenPdf({
    required BusinessConfig? config,
    required CashRegister register,
    required String symbol,
    PdfPageFormat? pageFormat,
  }) =>
      ThermalOpsText.linesToPdf(
        buildOpenText(config: config, register: register, symbol: symbol),
        pageFormat: pageFormat,
      );

  static Future<Uint8List> buildMovementPdf({
    required BusinessConfig? config,
    required CashMovement movement,
    required String symbol,
    PdfPageFormat? pageFormat,
  }) =>
      ThermalOpsText.linesToPdf(
        buildMovementText(config: config, movement: movement, symbol: symbol),
        pageFormat: pageFormat,
      );
}
