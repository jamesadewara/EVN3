// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../database/database_helper.dart';
import '../providers/product_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/transaction_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        children: [
          _buildSection(
            context,
            'Data Management',
            [
              _buildExportButton(context),
              const SizedBox(height: 16),
              _buildSeedDemoDataButton(context, ref),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Scanner Settings',
            [
              _buildSwitchTile(
                'Enable Vibration',
                AppConfig.enableScannerVibration,
                (value) {},
              ),
              _buildSwitchTile(
                'Enable Sound',
                AppConfig.enableScannerSound,
                (value) {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Demo Mode',
            [
              _buildSwitchTile(
                'Enable Demo Mode',
                AppConfig.enableDemoMode,
                (value) {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'About',
            [
              ListTile(
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
                trailing: const Icon(Icons.info_outline),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'EVN3',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2023 EVN3 Inventory System',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConfig.defaultPadding),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _exportData(context),
      icon: const Icon(Icons.file_download),
      label: const Text('Export Data to CSV'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _buildSeedDemoDataButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        try {
          await ref.read(productProvider.notifier).seedDemoData();
          await ref.read(inventoryProvider.notifier).seedDemoData();
          await ref.read(transactionProvider.notifier).seedDemoData();
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demo data seeded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error seeding demo data: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.data_array),
      label: const Text('Seed Demo Data'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppConfig.primaryColor,
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: AppConfig.primaryColor,
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelper();
      final data = await dbHelper.getAllDataForExport();

      final csvData = const ListToCsvConverter().convert([
        ['Product ID', 'Name', 'Category', 'Quantity', 'Last Updated'],
        ...data['products'].map((product) {
          final inventoryItem = data['inventoryItems'].firstWhere(
            (item) => item['productId'] == product['id'],
            orElse: () => {'quantity': 0, 'lastUpdatedAt': ''},
          );
          return [
            product['id'],
            product['name'],
            product['category'],
            inventoryItem['quantity'],
            inventoryItem['lastUpdatedAt'],
          ];
        }),
      ]);

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toString().replaceAll(':', '-');
      final file = File(
        '${directory.path}/${AppConfig.exportFileName}_$timestamp.csv',
      );
      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'EVN3 Inventory Export',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}