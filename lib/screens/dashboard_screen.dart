import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_config.dart';
import '../providers/inventory_provider.dart';
import '../providers/product_provider.dart';
import '../models/inventory_item.dart';
import '../models/product.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(productProvider.notifier).loadProducts(),
            ref.read(inventoryProvider.notifier).loadInventoryItems(),
          ]);
        },
        child: productsAsync.when(
          data: (products) => inventoryAsync.when(
            data: (inventoryItems) => _buildDashboardContent(
              context,
              products,
              inventoryItems,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/scan');
        },
        backgroundColor: AppConfig.primaryColor,
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    List<Product> products,
    List<InventoryItem> inventoryItems,
  ) {
    // Create a map of product ID to inventory item for quick lookup
    final inventoryMap = {
      for (var item in inventoryItems) item.productId: item
    };

    // Calculate summary statistics
    final totalItems = products.length;
    final totalQuantity = inventoryItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final lowStockItems = inventoryItems.where((item) => item.quantity < 10).length;

    return CustomScrollView(
      slivers: [
        // Summary Statistics
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            child: Column(
              children: [
                _buildSummaryCard(
                  context,
                  [
                    _SummaryItem(
                      title: 'Total Items',
                      value: totalItems.toString(),
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                    ),
                    _SummaryItem(
                      title: 'Total Quantity',
                      value: totalQuantity.toString(),
                      icon: Icons.shopping_cart,
                      color: Colors.green,
                    ),
                    _SummaryItem(
                      title: 'Low Stock',
                      value: lowStockItems.toString(),
                      icon: Icons.warning,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Inventory List
        SliverPadding(
          padding: const EdgeInsets.all(AppConfig.defaultPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                final inventoryItem = inventoryMap[product.id];
                if (inventoryItem == null) return null;

                return _buildInventoryItemCard(
                  context,
                  product,
                  inventoryItem,
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 100 * index),
                      duration: const Duration(milliseconds: 300),
                    )
                    .slideX(
                      begin: 0.2,
                      end: 0,
                      delay: Duration(milliseconds: 100 * index),
                      duration: const Duration(milliseconds: 300),
                    );
              },
              childCount: products.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    List<_SummaryItem> items,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) => _buildSummaryItem(item)).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(_SummaryItem item) {
    return Column(
      children: [
        Icon(
          item.icon,
          color: item.color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          item.value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryItemCard(
    BuildContext context,
    Product product,
    InventoryItem inventoryItem,
  ) {
    final isLowStock = inventoryItem.quantity < 10;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConfig.defaultPadding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConfig.defaultPadding),
        leading: CircleAvatar(
          backgroundColor: AppConfig.primaryColor,
          child: Text(
            product.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
              'Location: ${inventoryItem.location ?? 'Not specified'}',
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
              '${inventoryItem.quantity} ${product.unitOfMeasure}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isLowStock ? Colors.red : Colors.black,
              ),
            ),
            if (isLowStock)
              Text(
                'Low Stock',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/item_details',
            arguments: product.id,
          );
        },
      ),
    );
  }
}

class _SummaryItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
} 