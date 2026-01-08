import '../models/dashboard_stats.dart';
import 'api_service.dart';

class DataService {
  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await ApiService.get('/dashboard/stats');

      // Convert API response to DashboardStats model
      List<ProductStock> lowStockProducts = [];
      if (response['low_stock_products'] != null) {
        lowStockProducts = (response['low_stock_products'] as List)
            .map((item) => ProductStock(
                  name: item['name'] ?? '',
                  quantity: item['quantity'] ?? 0,
                ))
            .toList();
      }

      return DashboardStats(
        totalProducts: response['total_products'] ?? 0,
        lowStockItems: response['low_stock_items'] ?? 0,
        totalCustomers: response['total_customers'] ?? 0,
        lowStockProducts: lowStockProducts,
        todaySalesTotal: (response['today_sales_total'] ?? 0).toDouble(),
        todayPurchasesTotal: (response['today_purchases_total'] ?? 0).toDouble(),
        totalSales: (response['total_sales'] ?? 0).toDouble(),
        totalGstCollected: (response['total_gst_collected'] ?? 0).toDouble(),
      );
    } catch (e) {
      // Fallback to mock data if API fails
      print('Failed to fetch dashboard stats: $e');
      return DashboardStats(
        totalProducts: 0,
        lowStockItems: 0,
        totalCustomers: 0,
        lowStockProducts: [],
        todaySalesTotal: 0.0,
        todayPurchasesTotal: 0.0,
        totalSales: 0.0,
        totalGstCollected: 0.0,
      );
    }
  }
}
