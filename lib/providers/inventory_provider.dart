// lib/providers/inventory_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';

final inventoryProvider = StateNotifierProvider<InventoryNotifier, AsyncValue<List<InventoryItem>>>((ref) {
  return InventoryNotifier();
});

class InventoryNotifier extends StateNotifier<AsyncValue<List<InventoryItem>>> {
  final _dbHelper = DatabaseHelper();
  final _apiService = ApiService();

  InventoryNotifier() : super(const AsyncValue.loading()) {
    loadInventoryItems();
  }

  Future<void> loadInventoryItems({bool fromApi = false}) async {
    try {
      state = const AsyncValue.loading();
      final items = fromApi
          ? await _apiService.getInventoryItems()
          : await _dbHelper.getAllInventoryItems();
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addInventoryItem(InventoryItem item, {bool toApi = false}) async {
    try {
      await _dbHelper.insertInventoryItem(item);
      await loadInventoryItems();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateInventoryItem(InventoryItem item, {bool toApi = false}) async {
    try {
      await _dbHelper.updateInventoryItem(item);
      await loadInventoryItems();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<InventoryItem?> getInventoryItem(String productId) async {
    try {
      return await _dbHelper.getInventoryItem(productId);
    } catch (e) {
      return null;
    }
  }

  Future<void> seedDemoData() async {
    try {
      await _dbHelper.seedDemoData();
      await loadInventoryItems();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}