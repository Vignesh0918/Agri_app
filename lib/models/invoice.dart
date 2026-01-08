class Invoice {
  final String invoiceNumber;
  final DateTime dateOfSale;
  final String customerName;
  final String customerPhone;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double basePrice; // Price without GST
  final double gstPercentage;
  final double gstAmount;
  final double totalPrice; // Final price including GST

  Invoice({
    required this.invoiceNumber,
    required this.dateOfSale,
    required this.customerName,
    required this.customerPhone,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.basePrice,
    required this.gstPercentage,
    required this.gstAmount,
    required this.totalPrice,
  });

  // Factory constructor to calculate GST automatically
  factory Invoice.create({
    required String invoiceNumber,
    required DateTime dateOfSale,
    required String customerName,
    required String customerPhone,
    required String itemName,
    required int quantity,
    required double unitPrice,
    required double gstPercentage,
  }) {
    final basePrice = quantity * unitPrice;
    final gstAmount = basePrice * (gstPercentage / 100);
    final totalPrice = basePrice + gstAmount;

    return Invoice(
      invoiceNumber: invoiceNumber,
      dateOfSale: dateOfSale,
      customerName: customerName,
      customerPhone: customerPhone,
      itemName: itemName,
      quantity: quantity,
      unitPrice: unitPrice,
      basePrice: basePrice,
      gstPercentage: gstPercentage,
      gstAmount: gstAmount,
      totalPrice: totalPrice,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'invoiceNumber': invoiceNumber,
      'dateOfSale': dateOfSale.toIso8601String(),
      'customerName': customerName,
      'customerPhone': customerPhone,
      'itemName': itemName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'basePrice': basePrice,
      'gstPercentage': gstPercentage,
      'gstAmount': gstAmount,
      'totalPrice': totalPrice,
    };
  }

  // Create from JSON
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceNumber: json['invoiceNumber'],
      dateOfSale: DateTime.parse(json['dateOfSale']),
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      itemName: json['itemName'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'],
      basePrice: json['basePrice'],
      gstPercentage: json['gstPercentage'],
      gstAmount: json['gstAmount'],
      totalPrice: json['totalPrice'],
    );
  }
}
