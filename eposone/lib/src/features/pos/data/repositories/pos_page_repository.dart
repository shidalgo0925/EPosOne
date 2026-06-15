import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eposone/src/core/database/database_provider.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page_item.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';

part 'pos_page_repository.g.dart';

typedef PosPageItemView = ({PosPageItem item, String label});

@riverpod
PosPageRepository posPageRepository(PosPageRepositoryRef ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return PosPageRepository(db);
}

class PosPageRepository {
  final Isar _isar;
  PosPageRepository(this._isar);

  Future<List<PosPage>> getActivePages() async {
    final pages = await _isar.posPages.filter().isDeletedEqualTo(false).isActiveEqualTo(true).findAll();
    pages.sort((a, b) {
      final o = a.sortOrder.compareTo(b.sortOrder);
      return o != 0 ? o : a.name.compareTo(b.name);
    });
    return pages;
  }

  Future<List<PosPage>> getAllPages() async {
    final pages = await _isar.posPages.filter().isDeletedEqualTo(false).findAll();
    pages.sort((a, b) {
      final o = a.sortOrder.compareTo(b.sortOrder);
      return o != 0 ? o : a.name.compareTo(b.name);
    });
    return pages;
  }

  Future<PosPage?> getPageById(String localId) async {
    return _isar.posPages.filter().localIdEqualTo(localId).findFirst();
  }

  Future<void> savePage(PosPage page) async {
    await _isar.writeTxn(() => _isar.posPages.put(page));
  }

  Future<void> deletePage(String localId) async {
    final page = await getPageById(localId);
    if (page == null) return;
    await _isar.writeTxn(() async {
      await _isar.posPages.put(page.markAsDeleted());
      final items = await getItems(localId);
      for (final item in items) {
        await _isar.posPageItems.put(item.markAsDeleted());
      }
    });
  }

  Future<List<PosPageItem>> getItems(String pageId) async {
    final items = await _isar.posPageItems.filter().pageIdEqualTo(pageId).isDeletedEqualTo(false).findAll();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  Future<void> setPageItems(String pageId, List<PosPageItem> items) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.posPageItems.filter().pageIdEqualTo(pageId).findAll();
      for (final old in existing) {
        await _isar.posPageItems.put(old.markAsDeleted());
      }
      for (var i = 0; i < items.length; i++) {
        await _isar.posPageItems.put(items[i].copyWith(pageId: pageId, sortOrder: i));
      }
    });
  }

  Future<List<Product>> resolveProductsForPage(String pageId, List<Product> allActiveProducts) async {
    final items = await getItems(pageId);
    if (items.isEmpty) return allActiveProducts;

    final byId = {for (final p in allActiveProducts) p.localId: p};
    final seen = <String>{};
    final result = <Product>[];

    for (final item in items) {
      if (item.itemType == PosPageItemType.product) {
        final product = byId[item.refId];
        if (product != null && seen.add(product.localId)) {
          result.add(product);
        }
      } else {
        final catProducts = allActiveProducts.where((p) => p.categoryId == item.refId).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        for (final product in catProducts) {
          if (seen.add(product.localId)) {
            result.add(product);
          }
        }
      }
    }

    return result;
  }

  Future<bool> hasConfiguredPages() async {
    final count = await _isar.posPages.filter().isDeletedEqualTo(false).isActiveEqualTo(true).count();
    return count > 0;
  }
}
