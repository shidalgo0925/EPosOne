import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Logo del comercio para recibo / factura (almacenamiento local).
abstract final class BusinessLogoStorage {
  static final _picker = ImagePicker();
  static const _fileName = 'business_logo';

  static Future<String?> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return null;
    return saveImage(file);
  }

  static Future<String?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return null;
    return saveImage(file);
  }

  static Future<String> saveImage(XFile file) async {
    final dir = await getApplicationDocumentsDirectory();
    final logosDir = Directory('${dir.path}/business_logos');
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }

    final ext = _fileExtension(file.path);
    final destPath = '${logosDir.path}/$_fileName$ext';

    // Quitar logo anterior con otra extensión.
    await clearAllIn(logosDir);

    await File(file.path).copy(destPath);
    return destPath;
  }

  static Future<void> clearAllIn(Directory logosDir) async {
    if (!await logosDir.exists()) return;
    await for (final entity in logosDir.list()) {
      if (entity is File) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static bool exists(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    return File(path).existsSync();
  }

  static String _fileExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= 0) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    if (ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp') {
      return ext == '.jpeg' ? '.jpg' : ext;
    }
    return '.jpg';
  }
}
