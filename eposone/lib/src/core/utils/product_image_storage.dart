import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Guarda fotos de producto en el almacenamiento local de la app.
abstract final class ProductImageStorage {
  static final _picker = ImagePicker();

  static Future<String?> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (file == null) return null;
    return saveImage(file);
  }

  static Future<String?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (file == null) return null;
    return saveImage(file);
  }

  static Future<String> saveImage(XFile file, {String? productId}) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/product_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = _fileExtension(file.path);
    final name = productId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final destPath = '${imagesDir.path}/$name$ext';

    await File(file.path).copy(destPath);
    return destPath;
  }

  static Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String _fileExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= 0) return '.jpg';
    return path.substring(dot);
  }
}
