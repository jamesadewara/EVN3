class InventoryItem {
  final String productId;
  final int quantity;
  final DateTime lastUpdatedAt;
  final String? location;

  InventoryItem({
    required this.productId,
    required this.quantity,
    required this.lastUpdatedAt,
    this.location,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      productId: json['productId'] as String,
      quantity: json['quantity'] as int,
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'location': location,
    };
  }

  InventoryItem copyWith({
    String? productId,
    int? quantity,
    DateTime? lastUpdatedAt,
    String? location,
  }) {
    return InventoryItem(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      location: location ?? this.location,
    );
  }
} 