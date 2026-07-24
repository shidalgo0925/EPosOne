import 'dart:io';
import 'dart:typed_data';

import 'package:eposone/src/core/utils/business_logo_storage.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Carga bytes del logo si existe en disco.
abstract final class ReceiptLogoLoader {
  static Future<Uint8List?> bytesFromConfig(BusinessConfig? config) async {
    final path = config?.logoPath;
    if (!BusinessLogoStorage.exists(path)) return null;
    try {
      return await File(path!).readAsBytes();
    } catch (_) {
      return null;
    }
  }
}
