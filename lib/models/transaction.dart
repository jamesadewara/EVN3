class Transaction {
  final String id;
  final String productId;
  final String type; // 'add' or 'remove'
  final int quantityChanged;
  final DateTime timestamp;
  final String? user;

  Transaction({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantityChanged,
    required this.timestamp,
    this.user,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      productId: json['productId'] as String,
      type: json['type'] as String,
      quantityChanged: json['quantityChanged'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      user: json['user'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'type': type,
      'quantityChanged': quantityChanged,
      'timestamp': timestamp.toIso8601String(),
      'user': user,
    };
  }

  Transaction copyWith({
    String? id,
    String? productId,
    String? type,
    int? quantityChanged,
    DateTime? timestamp,
    String? user,
  }) {
    return Transaction(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      type: type ?? this.type,
      quantityChanged: quantityChanged ?? this.quantityChanged,
      timestamp: timestamp ?? this.timestamp,
      user: user ?? this.user,
    );
  }
} 