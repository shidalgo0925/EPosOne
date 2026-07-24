import 'dart:io';

import 'package:flutter/material.dart';
import 'package:eposone/src/core/time/en1_date_time_service.dart';
import 'package:eposone/src/features/platform/data/provisioning_store.dart';

/// Validación de reloj vs EN1 (Fase 1: header HTTP `Date`).
///
/// No bloquea operación; solo advierte y audita.
class En1ClockGuard {
  En1ClockGuard._();

  static Future<void> checkAndWarn(BuildContext context, {String? apiBaseUrl}) async {
    final warnings = <String>[];

    // 1) Zona del SO vs EN1
    if (En1DateTimeService.detectDeviceTimezoneMismatch()) {
      await En1DateTimeService.recordClockEvent(
        kind: 'device_timezone_mismatch',
        message: 'Device TZ != EN1 ${En1DateTimeService.en1TimezoneId}',
      );
      final msg = En1DateTimeService.timezoneMismatchWarningMessage();
      if (msg != null) warnings.add(msg);
    }

    // 2) Drift vía Date header
    final base = apiBaseUrl ?? (await ProvisioningStore.loadConfig())?.apiBaseUrl;
    if (base != null && base.isNotEmpty) {
      final dateHeader = await probeServerDateHeader(base);
      if (dateHeader != null) {
        final drift = await En1DateTimeService.applyServerDateHeader(dateHeader);
        final driftMsg = En1DateTimeService.driftWarningMessage(drift);
        if (driftMsg != null) warnings.add(driftMsg);
      }
    }

    if (!context.mounted || warnings.isEmpty) return;
    final text = warnings.join('\n\n');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 8),
        backgroundColor: Colors.orange.shade800,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// HEAD/GET a la base EN1; captura header `Date` (UTC del edge/servidor).
  static Future<String?> probeServerDateHeader(String apiBaseUrl) async {
    final base = apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) return null;
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final uri = Uri.parse(base);
      final req = await client.openUrl('HEAD', uri).timeout(const Duration(seconds: 8));
      final res = await req.close().timeout(const Duration(seconds: 8));
      await res.drain<void>();
      return res.headers.value(HttpHeaders.dateHeader);
    } catch (_) {
      try {
        client ??= HttpClient();
        final uri = Uri.parse(base);
        final req = await client.getUrl(uri).timeout(const Duration(seconds: 8));
        final res = await req.close().timeout(const Duration(seconds: 8));
        final date = res.headers.value(HttpHeaders.dateHeader);
        await res.drain<void>();
        return date;
      } catch (_) {
        return null;
      }
    } finally {
      client?.close(force: true);
    }
  }

  /// Solo audita drift (sin UI) — útil tras sync.
  static Future<void> checkQuiet({String? apiBaseUrl}) async {
    En1DateTimeService.detectDeviceTimezoneMismatch();
    final base = apiBaseUrl ?? (await ProvisioningStore.loadConfig())?.apiBaseUrl;
    if (base == null || base.isEmpty) return;
    final dateHeader = await probeServerDateHeader(base);
    if (dateHeader != null) {
      await En1DateTimeService.applyServerDateHeader(dateHeader);
    }
  }
}
