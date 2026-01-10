import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../services/data_service.dart';
import '../models/dashboard_stats.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double todaySalesTotal = 0.0;
  double todayPurchasesTotal = 0.0;
  bool isLoading = true;
  DashboardStats? stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactionService = TransactionService();
    final dataService = DataService();
    try {
      final sales = await transactionService.getTodaySalesTotal();
      final purchases = await transactionService.getTodayPurchasesTotal();
      final dashboardStats = await dataService.getDashboardStats();

      if (mounted) {
        setState(() {
          todaySalesTotal = sales;
          todayPurchasesTotal = purchases;
          stats = dashboardStats;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error loading report data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Reports & Analytics",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. STOCK SUMMARY
                  _buildSectionTitle("Stock Summary"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          title: "Total Products",
                          value: stats?.totalProducts.toString() ?? "0",
                          icon: Icons.inventory_2_rounded,
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          title: "Low Stock",
                          value: stats?.lowStockItems.toString() ?? "0",
                          icon: Icons.warning_rounded,
                          color: const Color(0xFFD32F2F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 2. SALES & PURCHASE SUMMARY
                  _buildSectionTitle("Today's Financials"),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.green.shade50, width: 2),
                    ),
                    child: Column(
                      children: [
                        _buildFinancialRow(
                          "Gross Sales",
                          "₹${todaySalesTotal.toStringAsFixed(0)}",
                          const Color(0xFF2E7D32),
                          Icons.trending_up_rounded,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1),
                        ),
                        _buildFinancialRow(
                          "Total Procurement",
                          "₹${todayPurchasesTotal.toStringAsFixed(0)}",
                          const Color(0xFF1976D2),
                          Icons.trending_down_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 3. LOW STOCK PRODUCTS
                  _buildSectionTitle("Critical Stock Alerts"),
                  if (stats != null && stats!.lowStockProducts.isNotEmpty)
                    Column(
                      children: stats!.lowStockProducts.map((p) {
                        return _buildModernLowStockItem(p.name, p.quantity);
                      }).toList(),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.green.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green[400], size: 40),
                          const SizedBox(height: 12),
                          Text(
                            "All stock levels are healthy",
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String title, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernLowStockItem(String name, double qty) {
    final qtyDisplay = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.orange[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$qtyDisplay units",
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
