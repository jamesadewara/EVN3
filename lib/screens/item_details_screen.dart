import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_config.dart';
import '../providers/product_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/product.dart';
import '../models/inventory_item.dart';
import '../models/transaction.dart';

class ItemDetailsScreen extends ConsumerWidget {
  final String productId;

  const ItemDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider).whenData(
          (products) => products.firstWhere((p) => p.id == productId),
        );

    final inventoryAsync = ref.watch(inventoryProvider).whenData(
          (items) => items.firstWhere((i) => i.productId == productId),
        );

    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/transactions',
                arguments: productId,
              );
            },
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) => inventoryAsync.when(
          data: (inventoryItem) => _buildContent(
            context,
            ref,
            product,
            inventoryItem,
            transactionsAsync,
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Product product,
    InventoryItem inventoryItem,
    AsyncValue<List<Transaction>> transactionsAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(context, ref, product, inventoryItem)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.2, end: 0, duration: 300.ms),
          const SizedBox(height: 24),
          _buildProductDetails(context, product)
              .animate()
              .fadeIn(delay: 200.ms, duration: 300.ms)
              .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 24),
          _buildRecentTransactions(context, transactionsAsync)
              .animate()
              .fadeIn(delay: 400.ms, duration: 300.ms)
              .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildProductHeader(
    BuildContext context,
    WidgetRef ref,
    Product product,
    InventoryItem inventoryItem,
  ) {
    final isLowStock = inventoryItem.quantity < 10;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppConfig.primaryColor,
                  child: Text(
                    product.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Stock',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${inventoryItem.quantity} ${product.unitOfMeasure}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isLowStock ? Colors.red : Colors.black,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showQuantityDialog(context, ref, product),
                  icon: const Icon(Icons.edit),
                  label: const Text('Adjust'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails(BuildContext context, Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Barcode', product.barcode),
            if (product.description != null)
              _buildDetailRow('Description', product.description!),
            _buildDetailRow('Category', product.category),
            _buildDetailRow('Unit of Measure', product.unitOfMeasure),
            if (product.price != null)
              _buildDetailRow('Price', '\$${product.price!.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    AsyncValue<List<Transaction>> transactionsAsync,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/transactions',
                      arguments: productId,
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            transactionsAsync.when(
              data: (transactions) {
                final productTransactions = transactions
                    .where((t) => t.productId == productId)
                    .take(3)
                    .toList();

                if (productTransactions.isEmpty) {
                  return const Center(
                    child: Text('No recent transactions'),
                  );
                }

                return Column(
                  children: productTransactions
                      .map((transaction) => _buildTransactionTile(transaction))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final isAddition = transaction.type == 'add';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isAddition ? Colors.green : Colors.red,
        child: Icon(
          isAddition ? Icons.add : Icons.remove,
          color: Colors.white,
        ),
      ),
      title: Text(
        _formatDate(transaction.timestamp),
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Text(
        '${isAddition ? '+' : '-'}${transaction.quantityChanged}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isAddition ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Quantity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: ${product.name}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _adjustQuantity(context, ref, product, -1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('-1'),
                ),
                ElevatedButton(
                  onPressed: () => _adjustQuantity(context, ref, product, 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('+1'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showCustomQuantityDialog(context, ref, product),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Custom Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCustomQuantityDialog(BuildContext context, WidgetRef ref, Product product) {
    final quantityController = TextEditingController();
    bool isAdd = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Custom Quantity Adjustment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Product: ${product.name}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ToggleButtons(
                  isSelected: [isAdd, !isAdd],
                  onPressed: (index) {
                    setState(() {
                      isAdd = index == 0;
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Add'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final quantity = int.tryParse(quantityController.text) ?? 0;
                  if (quantity > 0) {
                    Navigator.pop(context);
                    _adjustQuantity(
                      context,
                      ref,
                      product,
                      isAdd ? quantity : -quantity,
                    );
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _adjustQuantity(
    BuildContext context,
    WidgetRef ref,
    Product product,
    int change,
  ) async {
    try {
      final inventoryNotifier = ref.read(inventoryProvider.notifier);
      final transactionNotifier = ref.read(transactionProvider.notifier);

      final inventoryItem = await inventoryNotifier.getInventoryItem(product.id);

      if (inventoryItem == null) {
        final newItem = InventoryItem(
          productId: product.id,
          quantity: change > 0 ? change : 0,
          lastUpdatedAt: DateTime.now(),
        );
        await inventoryNotifier.addInventoryItem(newItem);
      } else {
        final newQuantity = inventoryItem.quantity + change;
        final updatedItem = inventoryItem.copyWith(
          quantity: newQuantity > 0 ? newQuantity : 0,
          lastUpdatedAt: DateTime.now(),
        );
        await inventoryNotifier.updateInventoryItem(updatedItem);
      }

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: product.id,
        type: change > 0 ? 'add' : 'remove',
        quantityChanged: change.abs(),
        timestamp: DateTime.now(),
      );
      await transactionNotifier.addTransaction(transaction);

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quantity ${change > 0 ? 'increased' : 'decreased'} by ${change.abs()}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider).whenData(
          (products) => products.firstWhere((p) => p.id == productId),
        );

    productAsync.when(
      data: (product) {
        final nameController = TextEditingController(text: product.name);
        final descController = TextEditingController(text: product.description);
        final categoryController = TextEditingController(text: product.category);
        final unitController = TextEditingController(text: product.unitOfMeasure);
        final priceController = TextEditingController(
          text: product.price?.toStringAsFixed(2) ?? '',
        );

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Edit Product'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit of Measure',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final updatedProduct = product.copyWith(
                    name: nameController.text,
                    description: descController.text,
                    category: categoryController.text,
                    unitOfMeasure: unitController.text,
                    price: double.tryParse(priceController.text),
                  );

                  try {
                    await ref.read(productProvider.notifier).updateProduct(
                          updatedProduct,
                          toApi: true,
                        );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating product: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}