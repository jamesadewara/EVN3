// lib/screens/transaction_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_config.dart';
import '../providers/transaction_provider.dart';
import '../providers/product_provider.dart';
import '../models/transaction.dart';
import '../models/product.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final String? productId;

  const TransactionHistoryScreen({
    super.key,
    this.productId,
  });

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  String _selectedFilter = 'all';
  String _selectedSort = 'newest';
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null
            ? 'All Transactions'
            : 'Product Transactions'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) => productsAsync.when(
          data: (products) => _buildTransactionList(
            context,
            _filterTransactions(transactions),
            products,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final newFilter = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Transaction Type:'),
            RadioListTile(
              title: const Text('All'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile(
              title: const Text('Additions Only'),
              value: 'add',
              groupValue: _selectedFilter,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile(
              title: const Text('Removals Only'),
              value: 'remove',
              groupValue: _selectedFilter,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            const Divider(),
            const Text('Sort Order:'),
            RadioListTile(
              title: const Text('Newest First'),
              value: 'newest',
              groupValue: _selectedSort,
              onChanged: (value) => Navigator.pop(context, _selectedFilter),
            ),
            RadioListTile(
              title: const Text('Oldest First'),
              value: 'oldest',
              groupValue: _selectedSort,
              onChanged: (value) => Navigator.pop(context, _selectedFilter),
            ),
            const Divider(),
            ListTile(
              title: const Text('Date Range'),
              subtitle: Text(
                _selectedDateRange == null
                    ? 'All dates'
                    : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final initialDateRange = _selectedDateRange ??
                    DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 30)),
                      end: DateTime.now(),
                    );
                final newDateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: initialDateRange,
                );
                if (newDateRange != null) {
                  setState(() => _selectedDateRange = newDateRange);
                }
                Navigator.pop(context, _selectedFilter);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'all';
                _selectedSort = 'newest';
                _selectedDateRange = null;
              });
              Navigator.pop(context, 'all');
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedFilter),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (newFilter != null) {
      setState(() => _selectedFilter = newFilter);
    }
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    var filtered = transactions;

    // Apply product filter if specified
    if (widget.productId != null) {
      filtered = filtered
          .where((t) => t.productId == widget.productId)
          .toList();
    }

    // Apply type filter
    if (_selectedFilter != 'all') {
      filtered = filtered
          .where((t) => t.type == _selectedFilter)
          .toList();
    }

    // Apply date range filter
    if (_selectedDateRange != null) {
      filtered = filtered
          .where((t) =>
              t.timestamp.isAfter(_selectedDateRange!.start) &&
              t.timestamp.isBefore(_selectedDateRange!.end))
          .toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      if (_selectedSort == 'newest') {
        return b.timestamp.compareTo(a.timestamp);
      } else {
        return a.timestamp.compareTo(b.timestamp);
      }
    });

    return filtered;
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<Transaction> transactions,
    List<Product> products,
  ) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text('No transactions found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final product = products.firstWhere(
          (p) => p.id == transaction.productId,
          orElse: () => Product(
            id: 'unknown',
            barcode: 'unknown',
            name: 'Unknown Product',
            category: 'Unknown',
            unitOfMeasure: 'units',
          ),
        );

        return _buildTransactionCard(
          context,
          transaction,
          product,
        )
            .animate()
            .fadeIn(delay: (50 * index).ms, duration: 300.ms)
            .slideX(begin: 0.2, end: 0, delay: (50 * index).ms, duration: 300.ms);
      },
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    Transaction transaction,
    Product product,
  ) {
    final isAddition = transaction.type == 'add';

    return Card(
      margin: const EdgeInsets.only(bottom: AppConfig.defaultPadding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConfig.defaultPadding),
        leading: CircleAvatar(
          backgroundColor: isAddition ? Colors.green : Colors.red,
          child: Icon(
            isAddition ? Icons.add : Icons.remove,
            color: Colors.white,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Category: ${product.category}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${_formatDate(transaction.timestamp)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isAddition ? '+' : '-'}${transaction.quantityChanged}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isAddition ? Colors.green : Colors.red,
              ),
            ),
            Text(
              product.unitOfMeasure,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/item_details',
            arguments: {'productId': product.id},
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}