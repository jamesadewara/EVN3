import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../models/product.dart';
import '../models/inventory_item.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static sqflite.Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal() {
    // Initialize FFI
    sqflite.sqfliteFfiInit();
  }

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<sqflite.Database> _initDatabase() async {
    final databaseFactory = sqflite.databaseFactoryFfi;
    String path;
    
    if (await databaseFactory.databaseExists(AppConfig.databaseName)) {
      path = join(await sqflite.getDatabasesPath(), AppConfig.databaseName);
    } else {
      // For new database
      final dbFolder = await getApplicationDocumentsDirectory();
      path = join(dbFolder.path, AppConfig.databaseName);
    }

    return await databaseFactory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: AppConfig.databaseVersion,
        onCreate: _onCreate,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

Future<void> _onCreate(sqflite.Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY,
        barcode TEXT UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        unitOfMeasure TEXT NOT NULL,
        price REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_items(
        productId TEXT PRIMARY KEY,
        quantity INTEGER NOT NULL,
        lastUpdatedAt TEXT NOT NULL,
        location TEXT,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        type TEXT NOT NULL,
        quantityChanged INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        user TEXT,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');
  }

  // ========== Product Operations ==========

  Future<String> insertProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toJson());
    return product.id;
  }

  Future<Product?> getProduct(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Product.fromJson(maps.first);
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (maps.isEmpty) return null;
    return Product.fromJson(maps.first);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromJson(maps[i]));
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toJson(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(String id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== Inventory Operations ==========

  Future<String> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    await db.insert('inventory_items', item.toJson());
    return item.productId;
  }

  Future<InventoryItem?> getInventoryItem(String productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'inventory_items',
      where: 'productId = ?',
      whereArgs: [productId],
    );
    if (maps.isEmpty) return null;
    return InventoryItem.fromJson(maps.first);
  }

  Future<List<InventoryItem>> getAllInventoryItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('inventory_items');
    return List.generate(maps.length, (i) => InventoryItem.fromJson(maps[i]));
  }

  Future<int> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.update(
      'inventory_items',
      item.toJson(),
      where: 'productId = ?',
      whereArgs: [item.productId],
    );
  }

  // ========== Transaction Operations ==========

  Future<String> insertTransaction(Transaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toJson());
    return transaction.id;
  }

  Future<List<Transaction>> getTransactionsForProduct(String productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromJson(maps[i]));
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromJson(maps[i]));
  }

  // ========== Data Export ==========

  Future<Map<String, dynamic>> getAllDataForExport() async {
    final db = await database;
    
    final products = await db.query('products');
    final inventoryItems = await db.query('inventory_items');
    final transactions = await db.query('transactions');

    return {
      'products': products,
      'inventoryItems': inventoryItems,
      'transactions': transactions,
    };
  }

  // ========== API Operations ==========

  Future<List<Product>> fetchProductsFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.mockarooBaseUrl}${AppConfig.productsEndpoint}?key=${AppConfig.mockarooApiKey}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<List<InventoryItem>> fetchInventoryFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.mockarooBaseUrl}${AppConfig.inventoryEndpoint}?key=${AppConfig.mockarooApiKey}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => InventoryItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load inventory: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<List<Transaction>> fetchTransactionsFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.mockarooBaseUrl}${AppConfig.transactionsEndpoint}?key=${AppConfig.mockarooApiKey}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  // ========== Demo Data Seeding ==========

  Future<void> seedDemoData() async {
    final db = await database;
    
    // Clear existing data
    await db.delete('transactions');
    await db.delete('inventory_items');
    await db.delete('products');

    // Fetch new data from API
    final products = await fetchProductsFromApi();
    final inventoryItems = await fetchInventoryFromApi();
    final transactions = await fetchTransactionsFromApi();

    // Insert new data in a transaction
    await db.transaction((txn) async {
      for (final product in products) {
        await txn.insert('products', product.toJson());
      }
      for (final item in inventoryItems) {
        await txn.insert('inventory_items', item.toJson());
      }
      for (final transaction in transactions) {
        await txn.insert('transactions', transaction.toJson());
      }
    });
  }
}