import '../models/transaction_record.dart';
import 'api_service.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();

  factory TransactionService() {
    return _instance;
  }

  TransactionService._internal();

  // Get all transactions
  Future<List<TransactionRecord>> getAllTransactions({
    int skip = 0,
    int limit = 100,
    TransactionType? transactionType,
    String? search,
  }) async {
    try {
      String endpoint = '/transactions/?skip=$skip&limit=$limit';
      if (transactionType != null) endpoint += '&transaction_type=${transactionType.name}';
      if (search != null) endpoint += '&search=$search';

      final response = await ApiService.get(endpoint);
      final List<dynamic> transactionsData = response as List<dynamic>;

      return transactionsData.map((data) => TransactionRecord(
        id: data['id'] ?? '',
        type: data['type'] == 'sale' ? TransactionType.sale : TransactionType.purchase,
        partyName: data['party_name'] ?? '',
        phoneNumber: data['phone_number'] ?? '',
        productName: data['product_name'] ?? '',
        quantity: (data['quantity'] ?? 1).toDouble(),
        unitPrice: (data['unit_price'] ?? 0).toDouble(),
        basePrice: (data['base_price'] ?? 0).toDouble(),
        gstPercentage: (data['gst_percentage'] ?? 0).toDouble(),
        gstAmount: (data['gst_amount'] ?? 0).toDouble(),
        totalAmount: (data['total_amount'] ?? 0).toDouble(),
        date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
        invoiceNumber: data['invoice_number'],
      )).toList();
    } catch (e) {
      print('Failed to fetch transactions: $e');
      return [];
    }
  }

  // Get transaction summary
  Future<Map<String, dynamic>?> getTransactionSummary() async {
    try {
      final response = await ApiService.get('/transactions/summary');
      return response;
    } catch (e) {
      print('Failed to fetch transaction summary: $e');
      return null;
    }
  }

  // Create transaction
  Future<TransactionRecord?> createTransaction(TransactionRecord transaction) async {
    try {
      final transactionData = {
        'type': transaction.type.name,
        'party_name': transaction.partyName,
        'phone_number': transaction.phoneNumber,
        'product_name': transaction.productName,
        'quantity': transaction.quantity,
        'unit_price': transaction.unitPrice,
        'gst_percentage': transaction.gstPercentage,
        'date': transaction.date.toIso8601String(),
      };

      final response = await ApiService.post('/transactions/', transactionData);

      return TransactionRecord(
        id: response['id'] ?? '',
        type: response['type'] == 'sale' ? TransactionType.sale : TransactionType.purchase,
        partyName: response['party_name'] ?? '',
        phoneNumber: response['phone_number'] ?? '',
        productName: response['product_name'] ?? '',
        quantity: (response['quantity'] ?? 1).toDouble(),
        unitPrice: (response['unit_price'] ?? 0).toDouble(),
        basePrice: (response['base_price'] ?? 0).toDouble(),
        gstPercentage: (response['gst_percentage'] ?? 0).toDouble(),
        gstAmount: (response['gst_amount'] ?? 0).toDouble(),
        totalAmount: (response['total_amount'] ?? 0).toDouble(),
        date: DateTime.parse(response['date'] ?? DateTime.now().toIso8601String()),
        invoiceNumber: response['invoice_number'],
      );
    } catch (e) {
      print('Failed to create transaction: $e');
      return null;
    }
  }

  // Get transactions by date range
  Future<List<TransactionRecord>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await ApiService.get(
        '/transactions/date-range/?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}'
      );
      final List<dynamic> transactionsData = response as List<dynamic>;

      return transactionsData.map((data) => TransactionRecord(
        id: data['id'] ?? '',
        type: data['type'] == 'sale' ? TransactionType.sale : TransactionType.purchase,
        partyName: data['party_name'] ?? '',
        phoneNumber: data['phone_number'] ?? '',
        productName: data['product_name'] ?? '',
        quantity: (data['quantity'] ?? 1).toDouble(),
        unitPrice: (data['unit_price'] ?? 0).toDouble(),
        basePrice: (data['base_price'] ?? 0).toDouble(),
        gstPercentage: (data['gst_percentage'] ?? 0).toDouble(),
        gstAmount: (data['gst_amount'] ?? 0).toDouble(),
        totalAmount: (data['total_amount'] ?? 0).toDouble(),
        date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
        invoiceNumber: data['invoice_number'],
      )).toList();
    } catch (e) {
      print('Failed to fetch transactions by date range: $e');
      return [];
    }
  }

  // Instance methods for backward compatibility
  Future<List<TransactionRecord>> get transactions async {
    return await getAllTransactions();
  }

  Future<List<TransactionRecord>> get sales async {
    return await getAllTransactions(transactionType: TransactionType.sale);
  }

  Future<List<TransactionRecord>> get purchases async {
    return await getAllTransactions(transactionType: TransactionType.purchase);
  }

  Future<double> getTodaySalesTotal() async {
    final summary = await getTransactionSummary();
    return (summary?['today_sales_total'] ?? 0).toDouble();
  }

  Future<double> getTodayPurchasesTotal() async {
    final summary = await getTransactionSummary();
    return (summary?['today_purchases_total'] ?? 0).toDouble();
  }

  void addTransaction(TransactionRecord record) {
    // This method is called synchronously by the UI
    // We'll need to make it async in the future, but for now we'll just create the transaction
    createTransaction(record).then((result) {
      if (result != null) {
        print('Transaction created successfully');
      } else {
        print('Failed to create transaction');
      }
    }).catchError((error) {
      print('Error creating transaction: $error');
    });
  }
}
