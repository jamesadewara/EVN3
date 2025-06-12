// lib/config/app_config.dart
import 'package:flutter/material.dart';

class AppConfig {
  // App Theme Colors
  static const Color primaryColor = Color(0xFF8B0000); // Wine color
  static const Color secondaryColor = Color(0xFF2C3E50);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color successColor = Color(0xFF2ECC71);

  // App Text Styles
  static const double headingFontSize = 24.0;
  static const double subheadingFontSize = 18.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 14.0;

  // App Dimensions
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultIconSize = 24.0;

  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration splashScreenDuration = Duration(seconds: 2);

  // Database Configuration
  static const String databaseName = 'evn3.db';
  static const int databaseVersion = 1;

  // Mockaroo Configuration
  static const String mockarooApiKey = '3e99bed0';
  static const String mockarooBaseUrl = 'https://my.api.mockaroo.com';

  // API Endpoints
  static const String productsEndpoint = '/products';
  static const String inventoryEndpoint = '/inventory';
  static const String transactionsEndpoint = '/transactions';

  // Export Configuration
  static const String exportFileName = 'inventory_export.csv';
  static const String exportDateFormat = 'yyyy-MM-dd_HH-mm-ss';

  // Scanner Configuration
  static const Duration scannerTimeout = Duration(seconds: 30);
  static bool enableScannerVibration = true;
  static bool enableScannerSound = true;

  // Demo Mode Configuration
  static bool enableDemoMode = true;
  static const Duration demoUpdateInterval = Duration(minutes: 5);
  static const int demoMaxTransactions = 100;

  // Asset Paths
  static const String demoDataPath = 'assets/data';
  static const String demoProductsPath = '$demoDataPath/products.json';
  static const String demoInventoryPath = '$demoDataPath/inventory.json';
  static const String demoTransactionsPath = '$demoDataPath/transactions.json';
}