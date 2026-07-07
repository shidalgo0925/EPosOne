import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:eposone/src/core/database/istmo_product_images.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';

const _assetPrefix = 'assets/catalog/istmo/';
const _filenameMapAsset = '${_assetPrefix}filename_map.json';

Map<String, String>? _filenameMap;

/// Copia imágenes empaquetadas a almacenamiento local y devuelve rutas absolutas por producto.
Future<Map<String, String>> installIstmoProductImages(Iterable<String> productKeys) async {
  final docs = await getApplicationDocumentsDirectory();
  final imagesDir = Directory('${docs.path}/product_images/istmo');
  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }

  final installed = <String, String>{};
  final assetCache = <String, String>{};

  for (final key in productKeys) {
    final assetFile = istmoImageAssetFile(key);
    if (assetFile == null) continue;

    var localPath = assetCache[assetFile];
    localPath ??= await _copyAssetToLocal(
      assetFile: assetFile,
      destPath: '${imagesDir.path}/$key.jpg',
    );
    if (localPath != null) {
      assetCache[assetFile] = localPath;
      installed[key] = localPath;
    }
  }

  return installed;
}

Future<void> attachIstmoProductImages(Isar isar) async {
  final products = await isar.products.where().findAll();
  final keys = products
      .where((p) => p.sku?.startsWith('IST-') ?? false)
      .map((p) => p.sku!.substring(4))
      .toList();

  if (keys.isEmpty) return;

  final imagePaths = await installIstmoProductImages(keys);

  await isar.writeTxn(() async {
    for (final product in products) {
      if (!(product.sku?.startsWith('IST-') ?? false)) continue;
      final key = product.sku!.substring(4);
      final path = imagePaths[key];
      if (path == null) continue;
      await isar.products.put(product.copyWith(imagePath: path));
    }
  });
}

Future<bool> needsIstmoImages(Isar isar) async {
  final products = await isar.products.where().findAll();
  return products.any(
    (p) =>
        (p.sku?.startsWith('IST-') ?? false) &&
        (p.imagePath == null || p.imagePath!.isEmpty),
  );
}

Future<Map<String, String>> _loadFilenameMap() async {
  if (_filenameMap != null) return _filenameMap!;
  final raw = await rootBundle.loadString(_filenameMapAsset);
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  _filenameMap = decoded.map((key, value) => MapEntry(key, value as String));
  return _filenameMap!;
}

Future<String?> _copyAssetToLocal({
  required String assetFile,
  required String destPath,
}) async {
  try {
    final map = await _loadFilenameMap();
    final resolved = map[assetFile] ?? assetFile;
    final data = await rootBundle.load('$_assetPrefix$resolved');
    final file = File(destPath);
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file.path;
  } catch (_) {
    return null;
  }
}
