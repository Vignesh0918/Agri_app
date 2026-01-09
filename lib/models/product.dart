class Product {
  final int id;
  final String name;
  final String? description;
  final String category;
  final double unitPrice;
  final double stockQuantity;
  final int minStockLevel;
  final String? supplierName;
  final String? supplierContact;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.unitPrice,
    required this.stockQuantity,
    required this.minStockLevel,
    this.supplierName,
    this.supplierContact,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? '',
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      stockQuantity: (json['stock_quantity'] ?? 0).toDouble(),
      minStockLevel: json['min_stock_level'] ?? 0,
      supplierName: json['supplier_name'],
      supplierContact: json['supplier_contact'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'unit_price': unitPrice,
      'stock_quantity': stockQuantity,
      'min_stock_level': minStockLevel,
      'supplier_name': supplierName,
      'supplier_contact': supplierContact,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class ProductStock {
  final String name;
  final double quantity;

  ProductStock({required this.name, required this.quantity});

  factory ProductStock.fromJson(Map<String, dynamic> json) {
    return ProductStock(
      name: json['name'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'quantity': quantity};
  }
}
