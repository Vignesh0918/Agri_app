import 'package:flutter/material.dart';

import '../services/transaction_service.dart';
import '../models/transaction_record.dart';
import 'package:intl/intl.dart';

class CustomerHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerHistoryScreen({super.key, required this.customer});

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  late Future<List<TransactionRecord>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = TransactionService().getCustomerTransactions(
      widget.customer['phone'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Transaction History", style: TextStyle(fontSize: 18)),
            Text(
              widget.customer['name'],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<TransactionRecord>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No transaction history available"),
            );
          }

          final history = snapshot.data!;

          return ListView.separated(
            itemCount: history.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = history[index];
              final isSale = item.type == TransactionType.sale;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: isSale
                      ? Colors.green.shade50
                      : Colors.blue.shade50,
                  child: Icon(
                    isSale
                        ? Icons.shopping_bag_outlined
                        : Icons.inventory_2_outlined,
                    color: isSale
                        ? Colors.green.shade800
                        : Colors.blue.shade800,
                  ),
                ),
                title: Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Qty: ${item.quantity} ${item.quantityUnit} • ${DateFormat('yyyy-MM-dd').format(item.date)}",
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${item.totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      isSale ? "SALE" : "PURCHASE",
                      style: TextStyle(
                        fontSize: 10,
                        color: isSale ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
