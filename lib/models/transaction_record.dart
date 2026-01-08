enum TransactionType { sale, purchase }

class TransactionRecord {
  final String id;
  final TransactionType type;
  final String partyName; // Customer Name or Supplier Name
  final String phoneNumber;

  final String productName;
  final int quantity;
  final double unitPrice;

  // GST-related fields (only for sales)
  final double basePrice; // Price without GST
  final double gstPercentage;
  final double gstAmount;
  final double totalAmount; // Final amount including GST

  final DateTime date;
  final String? invoiceNumber; // Only for sales

  TransactionRecord({
    required this.id,
    required this.type,
    required this.partyName,
    required this.phoneNumber,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.basePrice,
    this.gstPercentage = 0.0,
    this.gstAmount = 0.0,
    required this.totalAmount,
    required this.date,
    this.invoiceNumber,
  });
}
