// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/product.dart';
import '../models/inventory_item.dart';
import '../models/transaction.dart';

class ApiService {
  final String _baseUrl = AppConfig.mockarooBaseUrl;
  final String _apiKey = AppConfig.mockarooApiKey;

  Future<List<Product>> getProducts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl${AppConfig.productsEndpoint}?key=$_apiKey'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  Future<Product?> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$_baseUrl${AppConfig.productsEndpoint}?key=$_apiKey'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(product.toJson()),
    );

    if (response.statusCode == 201) {
      return Product.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<bool> updateProduct(Product product) async {
    final response = await http.put(
      Uri.parse('$_baseUrl${AppConfig.productsEndpoint}/${product.id}?key=$_apiKey'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(product.toJson()),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteProduct(String productId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl${AppConfig.productsEndpoint}/$productId?key=$_apiKey'),
      headers: {'Accept': 'application/json'},
    );

    return response.statusCode == 204;
  }

  Future<List<InventoryItem>> getInventoryItems() async {
    final response = await http.get(
      Uri.parse('$_baseUrl${AppConfig.inventoryEndpoint}?key=$_apiKey'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => InventoryItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load inventory: ${response.statusCode}');
    }
  }

  Future<List<Transaction>> getTransactions() async {
    final response = await http.get(
      Uri.parse('$_baseUrl${AppConfig.transactionsEndpoint}?key=$_apiKey'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load transactions: ${response.statusCode}');
    }
  }
}