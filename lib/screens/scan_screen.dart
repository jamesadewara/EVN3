import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart' show FlutterBarcodeSdk;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../models/inventory_item.dart';
import '../models/transaction.dart';
import '../providers/product_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/product.dart';
import 'package:permission_handler/permission_handler.dart';

// Platform-specific imports
import 'package:mobile_scanner/mobile_scanner.dart'
    if (dart.library.html) 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  // Mobile Scanner Controller
  MobileScannerController? _mobileScannerController;
  
  // Desktop Scanner
  dynamic _barcodeReader;
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isTorchOn = false;
  String? _lastScannedCode;
  String? _scanError;
  StreamSubscription<dynamic>? _barcodeSubscription;

  bool get _isMobilePlatform {
    return !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || 
                      defaultTargetPlatform == TargetPlatform.iOS);
  }

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      if (_isMobilePlatform) {
        await _initMobileScanner();
      } else {
        await _initDesktopScanner();
      }
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _scanError = 'Scanner initialization error: $e');
    }
  }

  Future<void> _initMobileScanner() async {
    _mobileScannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  Future<void> _initDesktopScanner() async {
    _barcodeReader = FlutterBarcodeSdk();
    await _barcodeReader.setLicense(
        'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==');
    await _barcodeReader.setBarcodeFormats(6); // 6 = BarcodeFormat.ALL
  }

  @override
  void dispose() {
    _mobileScannerController?.dispose();
    _barcodeSubscription?.cancel();
    if (!_isMobilePlatform && _barcodeReader != null) {
      _barcodeReader.stopScanning();
    }
    super.dispose();
  }

  Future<bool> _checkCameraPermission() async {
    if (!_isMobilePlatform) return true;
    
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  Future<void> _startScanning() async {
    if (!_isInitialized || _isScanning) return;

    if (_isMobilePlatform) {
      final hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        setState(() => _scanError = 'Camera permission denied');
        return;
      }
    }

    setState(() {
      _isScanning = true;
      _scanError = null;
    });

    try {
      if (_isMobilePlatform) {
        await _mobileScannerController!.start();
        _barcodeSubscription = _mobileScannerController!.barcodes.listen((barcode) {
          if (barcode.raw != null && barcode.raw != _lastScannedCode) {
            _lastScannedCode = barcode.raw;
            _handleBarcode(barcode.raw!);
          }
        });
      } else {
        _barcodeSubscription = _barcodeReader.onBarcodeResult.listen((result) {
          if (result.text.isNotEmpty && result.text != _lastScannedCode) {
            _lastScannedCode = result.text;
            _handleBarcode(result.text);
          }
        });
        await _barcodeReader.startScan();
      }
    } catch (e) {
      setState(() => _scanError = 'Scan error: $e');
      _stopScanning();
    }
  }

  Future<void> _stopScanning() async {
    try {
      if (_isMobilePlatform) {
        await _mobileScannerController!.stop();
      } else {
        await _barcodeReader.stopScanning();
      }
      _barcodeSubscription?.cancel();
    } catch (e) {
      debugPrint('Error stopping scanner: $e');
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      if (_isMobilePlatform) {
        await _mobileScannerController!.toggleTorch();
      } else {
        await _barcodeReader.enableTorch(!_isTorchOn);
      }
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (e) {
      setState(() => _scanError = 'Failed to toggle torch: $e');
    }
  }

  Future<void> _handleBarcode(String barcode) async {
    await _stopScanning();
    
    try {
      final product = await ref
          .read(productProvider.notifier)
          .getProductByBarcode(barcode);

      if (!mounted) return;

      if (product != null) {
        _showProductFoundDialog(product);
      } else {
        _showProductNotFoundDialog(barcode);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showProductFoundDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${product.name}'),
            const SizedBox(height: 8),
            Text('Barcode: ${product.barcode}'),
            const SizedBox(height: 8),
            Text('Category: ${product.category}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/item_details',
                arguments: {'productId': product.id},
              );
            },
            child: const Text('View Details'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showQuantityDialog(product);
            },
            child: const Text('Adjust Quantity'),
          ),
        ],
      ),
    );
  }

  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Text('No product found with barcode: $barcode'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/add_product',
                arguments: barcode,
              );
            },
            child: const Text('Add New Product'),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(Product product) {
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
                  onPressed: () => _adjustQuantity(product, -1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('-1'),
                ),
                ElevatedButton(
                  onPressed: () => _adjustQuantity(product, 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('+1'),
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
        ],
      ),
    );
  }

  Future<void> _adjustQuantity(Product product, int change) async {
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

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quantity ${change > 0 ? 'increased' : 'decreased'} by ${change.abs()}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isInitialized && _isMobilePlatform) // Torch only for mobile
            IconButton(
              icon: Icon(_isTorchOn ? Icons.flash_off : Icons.flash_on),
              onPressed: _toggleTorch,
              tooltip: 'Toggle Flash',
            ),
        ],
      ),
      body: _buildScannerContent(),
    );
  }

  Widget _buildScannerContent() {
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Initializing scanner...'),
          ],
        ),
      );
    }

    if (_isMobilePlatform) {
      return _buildMobileScanner();
    } else {
      return _buildDesktopScannerUI();
    }
  }

  Widget _buildMobileScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _mobileScannerController,
          fit: BoxFit.contain,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final barcode = barcodes.first;
              if (barcode.rawValue != null && barcode.rawValue != _lastScannedCode) {
                _lastScannedCode = barcode.rawValue;
                _handleBarcode(barcode.rawValue!);
              }
            }
          },
        ),
        if (_scanError != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black54,
              child: Text(
                _scanError!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: _isScanning ? _stopScanning : _startScanning,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(_isScanning ? 'STOP SCANNING' : 'START SCANNING'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopScannerUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_scanError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  _scanError!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_isScanning)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    'Scanning...',
                    style: TextStyle(
                      color: AppConfig.primaryColor,
                      fontSize: 18,
                    ),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _startScanning,
                icon: const Icon(Icons.qr_code_scanner, size: 30),
                label: const Text(
                  'START SCANNING',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            const SizedBox(height: 30),
            Text(
              'Align barcode with camera',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Icon(
              Icons.view_in_ar,
              size: 50,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}