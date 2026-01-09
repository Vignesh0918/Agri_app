class DashboardStats {
  final int totalProducts;
  final double totalStock;
  final int lowStockItems;
  final int totalCustomers;
  final List<ProductStock> lowStockProducts;
  final double todaySalesTotal;
  final double todayPurchasesTotal;
  final double totalSales;
  final double totalGstCollected;

  DashboardStats({
    required this.totalProducts,
    required this.totalStock,
    required this.lowStockItems,
    required this.totalCustomers,
    required this.lowStockProducts,
    this.todaySalesTotal = 0.0,
    this.todayPurchasesTotal = 0.0,
    this.totalSales = 0.0,
    this.totalGstCollected = 0.0,
  });
}

class ProductStock {
  final String name;
  final double quantity;

  ProductStock({required this.name, required this.quantity});
}
