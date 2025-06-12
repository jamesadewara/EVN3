class Product {
  final String id;
  final String barcode;
  final String name;
  final String? description;
  final String category;
  final String unitOfMeasure;
  final double? price;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    this.description,
    required this.category,
    required this.unitOfMeasure,
    this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      unitOfMeasure: json['unitOfMeasure'] as String,
      price: json['price'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'description': description,
      'category': category,
      'unitOfMeasure': unitOfMeasure,
      'price': price,
    };
  }

  Product copyWith({
    String? id,
    String? barcode,
    String? name,
    String? description,
    String? category,
    String? unitOfMeasure,
    double? price,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      price: price ?? this.price,
    );
  }
} 