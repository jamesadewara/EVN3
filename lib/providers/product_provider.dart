// lib/providers/product_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';

final productProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductNotifier();
});

class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final _dbHelper = DatabaseHelper();
  final _apiService = ApiService();

  ProductNotifier() : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts({bool fromApi = false}) async {
    try {
      state = const AsyncValue.loading();
      final products = fromApi
          ? await _apiService.getProducts()
          : await _dbHelper.getAllProducts();
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addProduct(Product product, {bool toApi = false}) async {
    try {
      if (toApi) {
        final createdProduct = await _apiService.createProduct(product);
        if (createdProduct != null) {
          await _dbHelper.insertProduct(createdProduct);
        }
      } else {
        await _dbHelper.insertProduct(product);
      }
      await loadProducts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProduct(Product product, {bool toApi = false}) async {
    try {
      if (toApi) {
        final success = await _apiService.updateProduct(product);
        if (success) {
          await _dbHelper.updateProduct(product);
        }
      } else {
        await _dbHelper.updateProduct(product);
      }
      await loadProducts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteProduct(String id, {bool fromApi = false}) async {
    try {
      if (fromApi) {
        final success = await _apiService.deleteProduct(id);
        if (success) {
          await _dbHelper.deleteProduct(id);
        }
      } else {
        await _dbHelper.deleteProduct(id);
      }
      await loadProducts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      return await _dbHelper.getProductByBarcode(barcode);
    } catch (e) {
      return null;
    }
  }

  Future<void> seedDemoData() async {
    try {
      await _dbHelper.seedDemoData();
      await loadProducts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}