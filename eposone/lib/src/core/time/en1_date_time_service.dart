import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Política oficial de zona horaria EPosOne (Fase 1).
///
/// - Persistencia / sync: UTC.
/// - Presentación: zona IANA de EN1 (`ProvisioningConfig.timezone`).
/// - El POS no es fuente oficial de la hora de negocio.
class En1DateTimeService {
  En1DateTimeService._();

  static const defaultTimezoneId = 'America/Panama';
  static const driftWarnThreshold = Duration(minutes: 2);
  static const _prefsTimezoneKey = 'en1_business_timezone_v1';
  static const _prefsDriftKey = 'en1_clock_drift_v1';
  static const _prefsAuditKey = 'en1_clock_audit_v1';
  static const _maxAuditEntries = 80;

  static bool _tzInitialized = false;
  static String _timezoneId = defaultTimezoneId;
  static Duration? _lastDrift;
  static DateTime? _lastServerUtc;
  static DateTime? _lastCheckedAtUtc;
  static String? _lastDeviceTimezoneLabel;
  static bool _timezoneMismatch = false;

  /// Inicializa la DB de zonas IANA. Llamar desde [main] antes de runApp.
  static void ensureInitialized() {
    if (_tzInitialized) return;
    tzdata.initializeTimeZones();
    _tzInitialized = true;
  }

  static String get en1TimezoneId => _timezoneId;

  static Duration? get lastDrift => _lastDrift;

  static DateTime? get lastServerUtc => _lastServerUtc;

  static DateTime? get lastCheckedAtUtc => _lastCheckedAtUtc;

  static bool get timezoneMismatch => _timezoneMismatch;

  static String? get lastDeviceTimezoneLabel => _lastDeviceTimezoneLabel;

  /// Carga timezone EN1 persistida (y estado de drift) al arrancar.
  static Future<void> hydrateFromPrefs() async {
    ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsTimezoneKey);
    if (saved != null && saved.trim().isNotEmpty) {
      _setTimezoneId(saved.trim());
    }
    final driftRaw = prefs.getString(_prefsDriftKey);
    if (driftRaw != null) {
      try {
        final m = jsonDecode(driftRaw) as Map<String, dynamic>;
        final driftMs = (m['driftMs'] as num?)?.toInt();
        if (driftMs != null) _lastDrift = Duration(milliseconds: driftMs);
        final serverIso = m['serverUtc'] as String?;
        if (serverIso != null) _lastServerUtc = DateTime.tryParse(serverIso)?.toUtc();
        final checkedIso = m['checkedAt'] as String?;
        if (checkedIso != null) _lastCheckedAtUtc = DateTime.tryParse(checkedIso)?.toUtc();
        _timezoneMismatch = m['timezoneMismatch'] == true;
        _lastDeviceTimezoneLabel = m['deviceTz'] as String?;
      } catch (_) {}
    }
  }

  /// Actualiza la zona de negocio desde provisioning/bootstrap EN1.
  static Future<void> setBusinessTimezone(String? ianaId) async {
    ensureInitialized();
    final id = (ianaId == null || ianaId.trim().isEmpty)
        ? defaultTimezoneId
        : ianaId.trim();
    _setTimezoneId(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsTimezoneKey, _timezoneId);
  }

  static void _setTimezoneId(String id) {
    try {
      tz.getLocation(id);
      _timezoneId = id;
    } catch (_) {
      debugPrint('[En1Clock] timezone inválida "$id" — usando $defaultTimezoneId');
      _timezoneId = defaultTimezoneId;
    }
  }

  /// Instante actual en UTC (persistencia / sync).
  static DateTime nowUtc() => DateTime.now().toUtc();

  /// Normaliza a UTC. Si el valor no es UTC, se interpreta como wall-clock local del device.
  static DateTime ensureUtc(DateTime value) {
    if (value.isUtc) return value;
    return value.toUtc();
  }

  /// ISO-8601 siempre con sufijo Z.
  static String toUtcIso(DateTime value) {
    final utc = ensureUtc(value);
    final iso = utc.toIso8601String();
    return iso.endsWith('Z') ? iso : '${iso}Z';
  }

  static tz.Location get _location {
    ensureInitialized();
    try {
      return tz.getLocation(_timezoneId);
    } catch (_) {
      return tz.getLocation(defaultTimezoneId);
    }
  }

  /// Convierte instante → hora de negocio EN1.
  static tz.TZDateTime toBusinessLocal(DateTime value) {
    return tz.TZDateTime.from(ensureUtc(value), _location);
  }

  /// Formato visible para cajero (nunca UTC crudo).
  static String formatLocal(DateTime value, [String pattern = 'dd/MM/yyyy HH:mm']) {
    final local = toBusinessLocal(value);
    return DateFormat(pattern).format(local);
  }

  static int deviceOffsetMinutes() => DateTime.now().timeZoneOffset.inMinutes;

  static String deviceTimezoneLabel() {
    final now = DateTime.now();
    final off = now.timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final abs = off.abs();
    final hh = abs.inHours.toString().padLeft(2, '0');
    final mm = (abs.inMinutes % 60).toString().padLeft(2, '0');
    return '${now.timeZoneName} (UTC$sign$hh:$mm)';
  }

  /// Offset de la zona EN1 en el instante dado (minutos).
  static int en1OffsetMinutes([DateTime? at]) {
    final local = toBusinessLocal(at ?? nowUtc());
    return local.timeZoneOffset.inMinutes;
  }

  /// True si el offset del device no coincide con el de la zona EN1.
  static bool detectDeviceTimezoneMismatch() {
    final deviceOff = deviceOffsetMinutes();
    final en1Off = en1OffsetMinutes();
    final mismatch = deviceOff != en1Off;
    _lastDeviceTimezoneLabel = deviceTimezoneLabel();
    _timezoneMismatch = mismatch;
    return mismatch;
  }

  /// Compara reloj del device con `Date` HTTP del servidor (GMT).
  /// Retorna el drift; si supera umbral, el caller muestra aviso.
  static Future<Duration> applyServerDateHeader(String? dateHeader) async {
    final server = _parseHttpDate(dateHeader);
    if (server == null) {
      return _lastDrift ?? Duration.zero;
    }
    final device = nowUtc();
    final drift = device.difference(server);
    final absDrift = drift.abs();
    _lastServerUtc = server;
    _lastCheckedAtUtc = device;
    _lastDrift = absDrift;

    await recordClockEvent(
      kind: 'server_date_check',
      message: absDrift > driftWarnThreshold
          ? 'Drift ${absDrift.inMinutes} min respecto al servidor'
          : 'Reloj OK (drift ${absDrift.inSeconds}s)',
      drift: absDrift,
    );
    await _persistDriftState();
    return absDrift;
  }

  static DateTime? _parseHttpDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      // RFC 1123: "Thu, 16 Jul 2026 23:41:06 GMT"
      return HttpDate.parse(raw.trim()).toUtc();
    } catch (_) {
      return DateTime.tryParse(raw)?.toUtc();
    }
  }

  /// Mensaje UX si el drift supera el umbral (null si OK).
  static String? driftWarningMessage([Duration? drift]) {
    final d = drift ?? _lastDrift;
    if (d == null || d <= driftWarnThreshold) return null;
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    final label = mins > 0 ? '$mins min' : '$secs s';
    return 'La hora de esta tablet tiene una diferencia de $label respecto al servidor.\n'
        'Se recomienda activar la fecha y hora automáticas del dispositivo.';
  }

  /// Mensaje si la zona del SO no coincide con EN1.
  static String? timezoneMismatchWarningMessage() {
    if (!_timezoneMismatch) return null;
    return 'La zona horaria del dispositivo (${_lastDeviceTimezoneLabel ?? 'desconocida'}) '
        'no coincide con la configurada en EN1 ($_timezoneId).\n'
        'La app mostrará la hora de negocio EN1; no se puede cambiar desde EPosOne.';
  }

  static Future<void> _persistDriftState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsDriftKey,
      jsonEncode({
        'driftMs': _lastDrift?.inMilliseconds,
        'serverUtc': _lastServerUtc?.toIso8601String(),
        'checkedAt': _lastCheckedAtUtc?.toIso8601String(),
        'timezoneMismatch': _timezoneMismatch,
        'deviceTz': _lastDeviceTimezoneLabel,
        'en1Tz': _timezoneId,
      }),
    );
  }

  static Future<void> recordClockEvent({
    required String kind,
    required String message,
    Duration? drift,
    DateTime? eventLocalWall,
  }) async {
    final utc = nowUtc();
    final wall = eventLocalWall ?? DateTime.now();
    final entry = {
      'atUtc': toUtcIso(utc),
      'atLocalWall': wall.toIso8601String(),
      'businessLocal': formatLocal(utc, 'yyyy-MM-dd HH:mm:ss'),
      'timezone': _timezoneId,
      'en1OffsetMin': en1OffsetMinutes(utc),
      'deviceOffsetMin': deviceOffsetMinutes(),
      'deviceTz': deviceTimezoneLabel(),
      'driftMs': (drift ?? _lastDrift)?.inMilliseconds,
      'kind': kind,
      'message': message,
    };
    debugPrint('[En1Clock] $kind · $message · tz=$_timezoneId');

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsAuditKey);
    final list = <Map<String, dynamic>>[];
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) list.add(Map<String, dynamic>.from(e));
          }
        }
      } catch (_) {}
    }
    list.insert(0, entry);
    while (list.length > _maxAuditEntries) {
      list.removeLast();
    }
    await prefs.setString(_prefsAuditKey, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> loadAuditLog({int limit = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsAuditKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final list = <Map<String, dynamic>>[];
      for (final e in decoded) {
        if (e is Map) list.add(Map<String, dynamic>.from(e));
        if (list.length >= limit) break;
      }
      return list;
    } catch (_) {
      return const [];
    }
  }

  static Future<String> auditLogAsText({int limit = 30}) async {
    final entries = await loadAuditLog(limit: limit);
    if (entries.isEmpty) return '(sin eventos de reloj)';
    final buf = StringBuffer();
    for (final e in entries) {
      buf.writeln(
        '${e['atUtc']} | ${e['kind']} | ${e['message']} | '
        'tz=${e['timezone']} | driftMs=${e['driftMs']}',
      );
    }
    return buf.toString();
  }
}
