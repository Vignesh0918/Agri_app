import 'package:flutter/material.dart';
import '../../models/transaction_record.dart';
import '../../services/transaction_service.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TransactionRecord> sales = [];
  List<TransactionRecord> purchases = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final service = TransactionService();
    try {
      final salesData = await service.sales;
      final purchasesData = await service.purchases;

      if (mounted) {
        setState(() {
          sales = salesData;
          purchases = purchasesData;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error loading transaction history: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Sales"),
            Tab(text: "Purchases"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildTransactionList(sales, true),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildTransactionList(purchases, false),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    List<TransactionRecord> transactions,
    bool isSale,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No ${isSale ? 'sales' : 'purchases'} recorded yet.",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final record = transactions[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: isSale
                  ? Colors.green.shade50
                  : Colors.blue.shade50,
              child: Icon(
                isSale ? Icons.sell : Icons.shopping_cart,
                color: isSale ? Colors.green.shade800 : Colors.blue.shade800,
              ),
            ),
            title: Text(
              record.productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("${isSale ? 'To' : 'From'}: ${record.partyName}"),
                Text(
                  "Phone: ${record.phoneNumber}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),

                Text(
                  "${DateFormat('MMM dd, yyyy').format(record.date)} • Qty: ${record.quantity}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Text(
              "\$${record.totalAmount.toStringAsFixed(2)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSale ? Colors.green.shade800 : Colors.blue.shade800,
              ),
            ),
          ),
        );
      },
    );
  }
}
