// lib/providers/transaction_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';

final transactionProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<List<Transaction>>>((ref) {
  return TransactionNotifier();
});

class TransactionNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final _dbHelper = DatabaseHelper();
  final _apiService = ApiService();

  TransactionNotifier() : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions({bool fromApi = false}) async {
    try {
      state = const AsyncValue.loading();
      final transactions = fromApi
          ? await _apiService.getTransactions()
          : await _dbHelper.getAllTransactions();
      state = AsyncValue.data(transactions.cast<Transaction>());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTransaction(Transaction transaction, {bool toApi = false}) async {
    try {
      await _dbHelper.insertTransaction(transaction);
      await loadTransactions();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<List> getTransactionsForProduct(String productId) async {
    try {
      return await _dbHelper.getTransactionsForProduct(productId);
    } catch (e) {
      return [];
    }
  }

  Future<void> seedDemoData() async {
    try {
      await _dbHelper.seedDemoData();
      await loadTransactions();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}