import '../models/invoice.dart';
import 'api_service.dart';

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();

  factory InvoiceService() {
    return _instance;
  }

  InvoiceService._internal();

  // Get all invoices from backend
  Future<List<Invoice>> getAllInvoices({int skip = 0, int limit = 100}) async {
    try {
      final response = await ApiService.get(
        '/invoices/?skip=$skip&limit=$limit',
      );
      final List<dynamic> invoicesData = response as List<dynamic>;

      return invoicesData
          .map(
            (data) => Invoice(
              invoiceNumber: data['invoice_number'] ?? '',
              dateOfSale: DateTime.parse(
                data['date_of_sale'] ?? DateTime.now().toIso8601String(),
              ),
              customerName: data['customer_name'] ?? '',
              customerPhone: data['customer_phone'] ?? '',
              itemName: data['item_name'] ?? '',
              quantity: data['quantity'] ?? 1,
              unitPrice: (data['unit_price'] ?? 0).toDouble(),
              basePrice: (data['base_price'] ?? 0).toDouble(),
              gstPercentage: (data['gst_percentage'] ?? 0).toDouble(),
              gstAmount: (data['gst_amount'] ?? 0).toDouble(),
              totalPrice: (data['total_price'] ?? 0).toDouble(),
            ),
          )
          .toList();
    } catch (e) {
      print('Failed to fetch invoices: $e');
      return [];
    }
  }

  // Get invoice by number from backend
  Future<Invoice?> getInvoiceByNumber(String invoiceNumber) async {
    try {
      final response = await ApiService.get('/invoices/number/$invoiceNumber');
      return Invoice(
        invoiceNumber: response['invoice_number'] ?? '',
        dateOfSale: DateTime.parse(
          response['date_of_sale'] ?? DateTime.now().toIso8601String(),
        ),
        customerName: response['customer_name'] ?? '',
        customerPhone: response['customer_phone'] ?? '',
        itemName: response['item_name'] ?? '',
        quantity: response['quantity'] ?? 1,
        unitPrice: (response['unit_price'] ?? 0).toDouble(),
        basePrice: (response['base_price'] ?? 0).toDouble(),
        gstPercentage: (response['gst_percentage'] ?? 0).toDouble(),
        gstAmount: (response['gst_amount'] ?? 0).toDouble(),
        totalPrice: (response['total_price'] ?? 0).toDouble(),
      );
    } catch (e) {
      print('Failed to fetch invoice: $e');
      return null;
    }
  }

  // Search invoices
  Future<List<Invoice>> searchInvoices(
    String query, {
    String searchType = 'customer',
  }) async {
    try {
      final response = await ApiService.post('/invoices/search', {
        'query': query,
        'search_type': searchType,
      });

      final List<dynamic> invoicesData = response as List<dynamic>;
      return invoicesData
          .map(
            (data) => Invoice(
              invoiceNumber: data['invoice_number'] ?? '',
              dateOfSale: DateTime.parse(
                data['date_of_sale'] ?? DateTime.now().toIso8601String(),
              ),
              customerName: data['customer_name'] ?? '',
              customerPhone: data['customer_phone'] ?? '',
              itemName: data['item_name'] ?? '',
              quantity: data['quantity'] ?? 1,
              unitPrice: (data['unit_price'] ?? 0).toDouble(),
              basePrice: (data['base_price'] ?? 0).toDouble(),
              gstPercentage: (data['gst_percentage'] ?? 0).toDouble(),
              gstAmount: (data['gst_amount'] ?? 0).toDouble(),
              totalPrice: (data['total_price'] ?? 0).toDouble(),
            ),
          )
          .toList();
    } catch (e) {
      print('Failed to search invoices: $e');
      return [];
    }
  }

  // Get today's invoices
  Future<List<Invoice>> getTodayInvoices() async {
    try {
      final response = await ApiService.get('/invoices/today/');
      final List<dynamic> invoicesData = response as List<dynamic>;

      return invoicesData
          .map(
            (data) => Invoice(
              invoiceNumber: data['invoice_number'] ?? '',
              dateOfSale: DateTime.parse(
                data['date_of_sale'] ?? DateTime.now().toIso8601String(),
              ),
              customerName: data['customer_name'] ?? '',
              customerPhone: data['customer_phone'] ?? '',
              itemName: data['item_name'] ?? '',
              quantity: data['quantity'] ?? 1,
              unitPrice: (data['unit_price'] ?? 0).toDouble(),
              basePrice: (data['base_price'] ?? 0).toDouble(),
              gstPercentage: (data['gst_percentage'] ?? 0).toDouble(),
              gstAmount: (data['gst_amount'] ?? 0).toDouble(),
              totalPrice: (data['total_price'] ?? 0).toDouble(),
            ),
          )
          .toList();
    } catch (e) {
      print('Failed to fetch today\'s invoices: $e');
      return [];
    }
  }

  // Get invoice summary
  Future<Map<String, dynamic>> getInvoiceSummary() async {
    try {
      return await ApiService.get('/invoices/summary');
    } catch (e) {
      print('Failed to fetch invoice summary: $e');
      return {
        'total_sales': 0.0,
        'total_gst_collected': 0.0,
        'total_invoices': 0,
      };
    }
  }

  // Legacy methods for backward compatibility (now return empty/default data)
  String generateInvoiceNumber() => '';
  void addInvoice(Invoice invoice) {}
  List<Invoice> get allInvoices => [];
  List<Invoice> searchByCustomer(String query) => [];
  List<Invoice> searchByInvoiceNumber(String query) => [];
  List<Invoice> getInvoicesByDateRange(DateTime start, DateTime end) => [];
  double getTotalSales() => 0.0;
  double getTotalGSTCollected() => 0.0;
}
