import 'package:flutter/material.dart';
import '../../models/transaction_record.dart';
import '../../services/transaction_service.dart';
import 'add_transaction_screen.dart';
import 'transaction_history_screen.dart';

class TransactionsHomeScreen extends StatefulWidget {
  const TransactionsHomeScreen({super.key});

  @override
  State<TransactionsHomeScreen> createState() => _TransactionsHomeScreenState();
}

class _TransactionsHomeScreenState extends State<TransactionsHomeScreen> {
  double todaySales = 0.0;
  double todayPurchases = 0.0;
  bool isLoading = true;
  bool _dataChanged = false;

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
          todaySales = sales;
          todayPurchases = purchases;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error loading transaction data: $e');
    }
  }

  void _refresh() {
    setState(() {
      isLoading = true;
      _dataChanged = true;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop && _dataChanged) {
          // Note: result cannot be sent via onPopInvoked directly in some versions,
          // but we can ensure the parent receives it if we use Navigator.pop(context, true)
          // in the leading button if present.
          // However, Navigator.push await will get the value if we pop with it.
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _dataChanged),
          ),
          title: const Text("Daily Transactions"),
          backgroundColor: Colors.blueGrey, // Distinct color for transactions
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: "History",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Today's Summary
              Card(
                elevation: 4,
                color: Colors.blueGrey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Today's Summary",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TransactionHistoryScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history, size: 18),
                            label: const Text("View All"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blueGrey,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              "Total Sales",
                              todaySales,
                              Colors.green,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              "Total Purchases",
                              todayPurchases,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Main Actions
              _buildActionCard(
                context,
                title: "Record Sale",
                subtitle: "Sell stock to customer",
                icon: Icons.sell,
                color: const Color(0xFF2E7D32),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTransactionScreen(
                        type: TransactionType.sale,
                      ),
                    ),
                  );
                  if (result == true) _refresh();
                },
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context,
                title: "Record Purchase",
                subtitle: "Buy stock from supplier",
                icon: Icons.shopping_cart,
                color: Colors.blue.shade800,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTransactionScreen(
                        type: TransactionType.purchase,
                      ),
                    ),
                  );
                  if (result == true) _refresh();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
