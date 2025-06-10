# EVN3: A Simple Inventory System

## Project Description

EVN3 is a cross-platform inventory management application built with Flutter, designed primarily for learning and demonstrating core concepts in logistics and mobile/desktop development. This app allows users to track physical inventory by scanning barcodes and QR codes, manage stock levels, view a simplified dashboard, and export data. It serves as a practical showcase of Flutter's capabilities for building functional and user-friendly business tools, with an emphasis on interactive and engaging user experiences through animations.

**Goals of this Project:**

* **Learn Logistics:** Gain practical understanding of inventory tracking, stock levels, and basic supply chain concepts.
* **Grow Tech Skills:** Enhance proficiency in Flutter development, local data persistence, barcode scanning integration, UI/UX design, and implementing interactive animations.
* **Practical Demonstration:** Showcase a tangible solution to a common logistical need.
* **Showcase on Social Media:** Create a polished, easily demonstrable application for portfolio and social media visibility, highlighted by smooth animations.

---

## 2. Development Tools, APIs, Models, and Schemas

### Development Tools

* **Flutter SDK:** The primary framework for building the application.
* **Dart:** The programming language used by Flutter.
* **Integrated Development Environment (IDE):** Visual Studio Code (VS Code) or Android Studio with Flutter/Dart plugins.
* **Platform SDKs:** Android SDK, iOS SDK (for macOS), Linux/Windows development tools.

### APIs & Packages

* **`mobile_scanner`:** For robust and efficient barcode/QR code scanning using the device camera. (Or `barcode_scan2` if `mobile_scanner` presents issues with specific platforms).
* **`path_provider`:** To get platform-specific paths for storing the local database.
* **`csv`:** For easily generating CSV formatted data for export.
* **`share_plus`:** For sharing the exported CSV file via native sharing sheets.
* **`google_fonts`:** To easily integrate and manage custom fonts like Open Sans and Roboto.
* **`flutter_launcher_icons`:** To customize the application's launcher icon across platforms.
* **`flutter_animate`:** A powerful and easy-to-use package for creating a wide variety of animations, perfect for making scrolling and component interactions more interactive.

### Models & Schemas

The application will primarily manage three core data models, reflecting the inventory structure. These models will be mapped from JSON data (generated via Mockaroo) into Dart objects for local persistence.

**2.1. `Product` Model**
Represents a unique item in the inventory.

* `id`: `String` (UUID recommended, or a unique integer)
* `barcode`: `String` (Unique identifier from barcode/QR code scan)
* `name`: `String` (Product name/title)
* `description`: `String?` (Optional detailed description)
* `category`: `String` (e.g., "Electronics", "Office Supplies", "Groceries")
* `unitOfMeasure`: `String` (e.g., "pcs", "kg", "box")
* `price`: `double?` (Optional, for future value tracking)

**2.2. `InventoryItem` Model**
Represents the current stock level of a specific `Product`.

* `productId`: `String` (Foreign key linking to `Product.id`)
* `quantity`: `int` (Current stock count)
* `lastUpdatedAt`: `DateTime` (Timestamp of the last quantity change)
* `location`: `String?` (Optional, e.g., "Warehouse A - A1", "Shelf 3")

**2.3. `Transaction` Model**
Represents an inventory movement (add or remove).

* `id`: `String` (UUID recommended)
* `productId`: `String` (Foreign key linking to `Product.id`)
* `type`: `String` (e.g., "add", "remove")
* `quantityChanged`: `int` (Number of units added or removed)
* `timestamp`: `DateTime` (When the transaction occurred)
* `user`: `String?` (Optional, e.g., "Scanner App Demo")

---

## 3. Best State Management & Storage Solutions

### State Management

For a project of this scope and complexity, aiming for simplicity and learnability while maintaining scalability, **Riverpod** is an excellent choice for state management.

* **Riverpod:**
    * **Benefits:** Compile-time safety, easy to test, robust dependency injection, simple to learn for new Flutter developers, and highly performant. It prevents common pitfalls of other providers by ensuring no global state.
    * **Alternative (if Riverpod feels too much initially):** `Provider` package. It's simpler for basic use cases but Riverpod is generally considered a safer and more scalable evolution.

### Local Storage

Given the requirement for local data persistence and structured data, a relational database is ideal.

* **`sqflite` (SQLite database):**
    * **Benefits:** Well-established, robust, and provides a structured way to store and query data. It's suitable for complex data relationships and provides full CRUD (Create, Read, Update, Delete) capabilities. Excellent for learning database concepts within Flutter.
    * **Alternative (for simpler, key-value storage):** `Hive`. Faster for very simple data but might be less ideal for complex queries or relationships needed for transactions and product lookups. `sqflite` offers a more comprehensive learning experience for structured data.

---

## 4. Data Seeding & Backend Simulation (Mockaroo)

For development and demonstration purposes, EVN3 utilizes **Mockaroo** as its primary source for realistic, fake data. This allows for robust testing of features without the need for a complex backend server.

**How Mockaroo is Integrated:**

* **Data Generation:** Mockaroo is used to generate large datasets for `Product`, `InventoryItem`, and `Transaction` models in JSON or CSV format. These files define the initial state of the inventory and a history of transactions.
* **Initial Data Seeding:** The generated JSON/CSV files are placed in the app's `assets/data/` directory. On the first launch (or via a "Seed Demo Data" option in settings), the app reads and parses these files, then populates the local `sqflite` database. This ensures a consistent and realistic starting point for the demo.
* **Backend Simulation (Conceptual):** While the app primarily uses local storage, Mockaroo's ability to create mock API endpoints provides a conceptual "backend" for future scalability. This approach allows for testing data fetching mechanisms and simulating network delays, even without a live server. For the current simple version, the focus remains on local data persistence with realistic data.
* **"Real-Time" Simulation:** Dynamic inventory changes for demonstration are handled client-side. The app includes a "Demo Mode" that programmatically generates new `Transaction` entries and updates `InventoryItem` quantities at random intervals, simulating live activity on the dashboard and transaction log.

---

## 5. Pages Needed for the Platform

The application will feature a clear and intuitive navigation structure, including the following key pages:

1.  **Splash Screen (`splash_screen.dart`):**
    * A brief introductory screen shown on app launch.
    * Loads initial data or performs setup tasks.

2.  **Dashboard Page (`dashboard_page.dart`):**
    * **Purpose:** The main overview of the inventory.
    * **Content:**
        * Summary statistics (e.g., total unique items, total quantity).
        * List of all `InventoryItem`s with product name, current quantity.
        * Visual cues for low stock items (if a reorder point is implemented).
        * Search/filter functionality for items.
        * Sort options (by name, quantity, last updated).

3.  **Scan Page (`scan_page.dart`):**
    * **Purpose:** Facilitate barcode/QR code scanning.
    * **Content:**
        * Camera view for scanning.
        * Flashlight toggle.
        * Display of scanned barcode/QR code data.
        * Options to "Add" or "Remove" quantity based on scan, or "Add New Product" if code is not found.
        * Manual input field for barcode/QR code if scanning fails.

4.  **Item Details Page (`item_details_page.dart`):**
    * **Purpose:** View and edit details of a specific product and its inventory.
    * **Content:**
        * Display `Product` details (name, description, category, barcode).
        * Display current `InventoryItem` quantity.
        * Option to manually adjust quantity (add/remove).
        * Button to view `Transaction` history for this specific item.
        * Option to edit product details (name, category etc.).

5.  **Transaction History Page (`transaction_history_page.dart`):**
    * **Purpose:** Display a log of all inventory movements.
    * **Content:**
        * List of all `Transaction` entries (product name, type, quantity changed, timestamp).
        * Filter options (by date range, product, type).
        * Sort options.

6.  **Settings/Export Page (`settings_page.dart`):**
    * **Purpose:** App settings and data export functionality.
    * **Content:**
        * Button to export all inventory data to CSV.
        * Option to "Seed Demo Data" (if implementing the internal simulation).
        * General app settings (e.g., dark mode toggle - if applicable).

---

## 6. UI Design Guides & Routing Guides

### UI Design Guides

* **Clean and Minimalist:** Prioritize clarity and ease of use. Avoid clutter.
* **Intuitive Navigation:** Use a bottom navigation bar for primary sections (Dashboard, Scan, Settings) on mobile. Use a `NavigationRail` or `Drawer` on desktop.
* **Action Buttons:** Use prominent Floating Action Buttons (FABs) or primary buttons for key actions (e.g., initiating a scan, saving changes).
* **Feedback:** Provide clear visual feedback for actions (e.g., successful scan, data saved, low stock alerts). Use Snackbars or Toast messages for temporary feedback.
* **Responsiveness:** Utilize Flutter's responsive widgets (e.g., `MediaQuery`, `LayoutBuilder`, `SizedBox`, `Expanded`) to ensure the UI adapts gracefully to different screen sizes (mobile phones, tablets, desktop windows).
* **Theming:** Implement a consistent color palette (e.g., a primary accent color is wine, dark and light modes).
* **Interactive Animations (`flutter_animate`):**
    * **Page Transitions:** Use subtle fade or slide animations when navigating between primary screens for a smoother feel.
    * **List Item Entry:** Animate list items (e.g., on Dashboard or Transaction History) as they appear on screen, perhaps with a slight slide-in or fade-in effect to draw attention.
    * **Component Interaction:** Add small animations to buttons on tap, or animate changes in quantity text on the dashboard.
    * **Data Updates:** When a quantity updates on the dashboard, consider a brief pulse or color change animation on the relevant `InventoryItem` to highlight the change.
    * **Loading Indicators:** Create custom, engaging loading animations for data fetching or processing.

### Routing Guides

Flutter's built-in navigation system is powerful. For simplicity and scalability:

* **Named Routes:** Define named routes for all primary pages (e.g., `/dashboard`, `/scan`, `/settings`). This makes navigation clear and allows for easier deep linking if needed later.
* **`Navigator.pushNamed()`:** Use this for navigating to new screens.
* **`Navigator.pop()`:** Use this to return to the previous screen.
* **`MaterialPageRoute` (for dynamic data):** When navigating to detail pages (e.g., `ItemDetailsPage`), pass arguments through the constructor or using `settings.arguments`.

**Example Routing Structure in `main.dart` or `app_router.dart`:**

```dart
MaterialApp(
  initialRoute: '/', // Or '/splash' if you have a splash screen
  routes: {
    '/': (context) => const DashboardPage(), // Or Home Page
    '/scan': (context) => const ScanPage(),
    '/item_details': (context) => const ItemDetailsPage(), // Handle arguments here
    '/transactions': (context) => const TransactionHistoryPage(),
    '/settings': (context) => const SettingsPage(),
    // Add specific routes for editing or creating new items
  },
  // OnGenerateRoute for complex argument passing or dynamic routes
  // onGenerateRoute: (settings) {
  //   if (settings.name == '/item_details') {
  //     final args = settings.arguments as Map<String, dynamic>;
  //     return MaterialPageRoute(
  //       builder: (context) {
  //         return ItemDetailsPage(productId: args['productId']);
  //       },
  //     );
  //   }
  //   return null;
  // },
);
```

---

## 7. Font Styles

To achieve a modern and clean aesthetic, the application will primarily use Google Fonts.

* **Primary Font:** `Open Sans`
    * **Usage:** Headings, prominent text, and general UI labels. Provides a clean, readable, and modern feel.
* **Secondary Font:** `Roboto`
    * **Usage:** Body text, smaller labels, and numeric displays (especially for quantities). Known for its excellent readability across various sizes.

**Integration with `google_fonts` package:**

Add `google_fonts` to your `pubspec.yaml`. Then, in your widgets:

```dart
import 'package:google_fonts/google_fonts.dart';

// Example for text style
Text(
  'Welcome to EVN3',
  style: GoogleFonts.openSans(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
);

Text(
  'Current Stock: 150 units',
  style: GoogleFonts.roboto(
    fontSize: 16,
    color: Colors.grey[700],
  ),
);
```

---

## 8. Splash Screen & Launcher Icon

### Splash Screen (`splash_screen.dart`)

The splash screen provides a brief visual introduction to the app while essential resources (like the local database) are being initialized.

* **Location:** Create a file `lib/screens/splash_screen.dart` (or `lib/features/splash/splash_screen.dart`).
* **Content:**
    * Centered app logo/icon.
    * Project name (EVN3) or a simple loading indicator.
    * **Consider a subtle animation for the logo or text using `flutter_animate` to make the splash screen more engaging.**
    * Perform asynchronous tasks:
        * Initialize the local database (`sqflite`).
        * Check if data needs to be seeded (e.g., on first run).
        * Load initial data from `assets/data/` if seeding is required.
    * Navigate to the `DashboardPage` after tasks are complete.

**Example Structure:**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Or Navigator.pushReplacementNamed
import 'package:flutter_animate/flutter_animate.dart'; // Import for animation

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate some loading time
    await Future.delayed(const Duration(seconds: 2));

    // TODO:
    // 1. Initialize your local database (sqflite)
    // 2. Check if data needs to be seeded (e.g., using SharedPreferences for a flag)
    // 3. If seeding, load data from assets/data/products.json, etc., and insert into DB.

    if (mounted) {
      // Navigate to the main dashboard
      context.go('/'); // Or Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo/icon here. Consider animating it:
            // Image.asset('assets/images/evn3_logo.png', width: 150, height: 150)
            //   .animate()
            //   .fade(duration: 500.ms)
            //   .slideY(begin: 0.2, duration: 500.ms),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'EVN3: Inventory System',
              style: Theme.of(context).textTheme.headlineSmall,
            ).animate() // Animate the text as well
             .fadeIn(duration: 600.ms, delay: 300.ms)
             .slideX(begin: -0.1, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
```

### Flutter Launcher Icons Package

The `flutter_launcher_icons` package makes it easy to update your app's launcher icon for Android, iOS, web, and desktop platforms from a single image file.

* **Installation:** Add `flutter_launcher_icons` to `dev_dependencies` in `pubspec.yaml`.
* **Configuration:** Add the following configuration to your `pubspec.yaml` file:

```yaml
dev_dependencies:
  flutter_lints: ^3.0.0
  flutter_launcher_icons: "^0.13.1" # Use the latest version

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icons/app_icon.png" # Path to your square icon image (e.g., 512x512px)
  min_sdk_android: 21 # android min sdk min:16, default 21
  remove_alpha_ios: true # Optional: remove transparency from iOS icon
  web:
    generate: true
    image_path: "assets/icons/app_icon.png"
    background_color: "#ffffff" # Optional: background color for web icon
    theme_color: "#ffffff" # Optional: theme color for web icon
  windows:
    generate: true
    image_path: "assets/icons/app_icon.png"
    icon_size: 48 # Optional: icon size for windows (must be 48 or 256)
  macos:
    generate: true
    image_path: "assets/icons/app_icon.png"
```

* **Usage:** After saving your icon file (e.g., `app_icon.png`) in `assets/icons/`, run the following command in your terminal:

    ```bash
    flutter pub get
    flutter pub run flutter_launcher_icons
    ```

This will generate and replace the default launcher icons with your custom icon.

---