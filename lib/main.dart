// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:evn3/config/app_config.dart';
import 'package:evn3/screens/splash_screen.dart';
import 'package:evn3/screens/dashboard_screen.dart';
import 'package:evn3/screens/scan_screen.dart';
import 'package:evn3/screens/item_details_screen.dart';
import 'package:evn3/screens/transaction_history_screen.dart';
import 'package:evn3/screens/settings_screen.dart';
import 'package:evn3/screens/add_product_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  runApp(
    const ProviderScope(
      child: EVN3App(),
    ),
  );
}

class EVN3App extends StatelessWidget {
  const EVN3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EVN3',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConfig.primaryColor,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.openSansTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.defaultBorderRadius),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/scan': (context) => const ScanScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/transactions': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return TransactionHistoryScreen(
            productId: args is String ? args : null,
          );
        },
        '/add_product': (context) {
          final barcode = ModalRoute.of(context)!.settings.arguments as String;
          return AddProductScreen(barcode: barcode);
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/item_details') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ItemDetailsScreen(
              productId: args['productId'] as String,
            ),
          );
        }
        return null;
      },
    );
  }
}