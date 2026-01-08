class Customer {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final double totalPurchases;
  final DateTime? lastPurchaseDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.gstNumber,
    required this.totalPurchases,
    this.lastPurchaseDate,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      address: json['address'],
      gstNumber: json['gst_number'],
      totalPurchases: (json['total_purchases'] ?? 0).toDouble(),
      lastPurchaseDate: json['last_purchase_date'] != null
          ? DateTime.parse(json['last_purchase_date'])
          : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'gst_number': gstNumber,
      'total_purchases': totalPurchases,
      'last_purchase_date': lastPurchaseDate?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
