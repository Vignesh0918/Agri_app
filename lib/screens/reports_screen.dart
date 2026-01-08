import 'package:flutter/material.dart';
import '../services/transaction_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double todaySalesTotal = 0.0;
  double todayPurchasesTotal = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = TransactionService();
    try {
      final sales = await service.getTodaySalesTotal();
      final purchases = await service.getTodayPurchasesTotal();

      if (mounted) {
        setState(() {
          todaySalesTotal = sales;
          todayPurchasesTotal = purchases;
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
    // Custom colors for reports
    final primaryColor = Colors.indigo.shade800;
    const cardColor = Colors.white;

    final service = TransactionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. STOCK SUMMARY
            _buildSectionTitle("Stock Summary"),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: "Total Products",
                    value: "145",
                    icon: Icons.inventory,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: "Low Stock",
                    value: "5",
                    icon: Icons.warning_amber,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. SALES & PURCHASE SUMMARY
            _buildSectionTitle("Today's Financials"),
            Card(
              elevation: 2,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSalesRow(
                      "Total Sales",
                      isLoading ? "Loading..." : "\$${todaySalesTotal.toStringAsFixed(2)}",
                      Colors.green,
                    ),
                    const Divider(height: 24),
                    _buildSalesRow(
                      "Total Purchases",
                      isLoading ? "Loading..." : "\$${todayPurchasesTotal.toStringAsFixed(2)}",
                      Colors.indigo,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. LOW STOCK PRODUCTS
            _buildSectionTitle("Low Stock Warnings"),
            Card(
              elevation: 2,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildMakeLowStockItem("Urea Fertilizer", 5),
                  const Divider(height: 1),
                  _buildMakeLowStockItem("Pesticide X-200", 2),
                  const Divider(height: 1),
                  _buildMakeLowStockItem("Tomato Seeds", 8),
                  const Divider(height: 1),
                  _buildMakeLowStockItem("Potash 50kg", 1),
                  const Divider(height: 1),
                  _buildMakeLowStockItem("NPK 20-20-20", 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesRow(String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMakeLowStockItem(String name, int qty) {
    return ListTile(
      leading: const Icon(Icons.error_outline, color: Colors.orange),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          "$qty left",
          style: TextStyle(
            color: Colors.red.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
