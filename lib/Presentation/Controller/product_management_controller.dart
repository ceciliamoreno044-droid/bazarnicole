import 'package:bazarnicole/Presentation/Services/catalog_sync_service.dart';
import 'package:bazarnicole/Presentation/Services/database_service.dart';
import 'package:flutter/foundation.dart';

class ProductManagementController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> stores = [];
  List<Map<String, dynamic>> categories = [];

  Future<void> initialize() async {
    if (isLoading || products.isNotEmpty) return;
    await loadCatalog();
  }

  Future<void> loadCatalog({String search = ''}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      stores = await DatabaseService.getStores();
      categories = await DatabaseService.getCategories();
      products = await DatabaseService.getProducts(search: search);
    } catch (e) {
      errorMessage = 'No se pudo cargar el catálogo: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProduct({
    required String name,
    required String category,
    required double price,
    double costPrice = 0,
    double ivaRate = 0,
    double profitIva = 0,
    String? sku,
    String? auxCode,
    String? description,
    String? tags,
    int? storeId,
    List<String> images = const [],
    Map<int, int> initialStock = const {},
  }) async {
    await DatabaseService.createProduct(
      name: name,
      price: price,
      costPrice: costPrice,
      ivaRate: ivaRate,
      profitIva: profitIva,
      categoryName: category,
      sku: sku,
      auxCode: auxCode,
      description: description,
      tags: tags,
      storeId: storeId,
      images: images,
      initialStock: initialStock,
    );
    await loadCatalog();
    CatalogSyncService.instance.markDirty(); // ← Producto creado
  }

  Future<void> updateProduct({
    required int productId,
    required String name,
    required String category,
    required double price,
    double costPrice = 0,
    double ivaRate = 0,
    double profitIva = 0,
    String? sku,
    String? auxCode,
    String? description,
    String? tags,
    int? storeId,
    List<String>? images,
  }) async {
    await DatabaseService.updateProduct(
      productId: productId,
      name: name,
      categoryName: category,
      sku: sku ?? '',
      price: price,
      costPrice: costPrice,
      ivaRate: ivaRate,
      profitIva: profitIva,
      auxCode: auxCode,
      description: description,
      tags: tags,
      storeId: storeId,
      images: images,
    );
    await loadCatalog();
    CatalogSyncService.instance.markDirty(); // ← Producto actualizado
  }

  Future<void> updateProductWithStock({
    required int productId,
    required String name,
    required String category,
    required double price,
    double costPrice = 0,
    double ivaRate = 0,
    double profitIva = 0,
    String? sku,
    String? auxCode,
    String? description,
    String? tags,
    int? storeId,
    List<String>? images,
    Map<int, int> stockByStore = const {},
  }) async {
    await DatabaseService.updateProduct(
      productId: productId,
      name: name,
      categoryName: category,
      sku: sku ?? '',
      price: price,
      costPrice: costPrice,
      ivaRate: ivaRate,
      profitIva: profitIva,
      auxCode: auxCode,
      description: description,
      tags: tags,
      storeId: storeId,
      images: images,
    );
    for (final entry in stockByStore.entries) {
      await DatabaseService.updateInventoryStock(
        productId: productId,
        storeId: entry.key,
        stock: entry.value,
      );
    }
    await loadCatalog();
    CatalogSyncService.instance.markDirty(); // ← Producto + stock actualizado
  }

  Future<void> deleteProduct(int productId) async {
    await DatabaseService.deleteProduct(productId);
    await loadCatalog();
    CatalogSyncService.instance.markDirty(); // ← Producto eliminado
  }
}
