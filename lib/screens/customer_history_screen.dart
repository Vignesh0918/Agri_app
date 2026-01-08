import 'package:flutter/material.dart';

class CustomerHistoryScreen extends StatelessWidget {
  final Map<String, dynamic> customer;

  const CustomerHistoryScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    // Dummy static data for purchase history
    final List<Map<String, dynamic>> history = [
      {
        'product': 'Urea Fertilizer',
        'quantity': 2,
        'date': '2024-12-25',
        'amount': 560.00,
      },
      {
        'product': 'Tomato Seeds',
        'quantity': 5,
        'date': '2024-12-20',
        'amount': 225.00,
      },
      {
        'product': 'Pesticide X-200',
        'quantity': 1,
        'date': '2024-11-15',
        'amount': 550.00,
      },
      {
        'product': 'NPK 19-19-19',
        'quantity': 3,
        'date': '2024-10-30',
        'amount': 3600.00,
      },
      {
        'product': 'Weed Killer RoundUp',
        'quantity': 2,
        'date': '2024-10-05',
        'amount': 960.00,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Purchase History", style: TextStyle(fontSize: 18)),
            Text(
              customer['name'],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
      ),
      body: history.isEmpty
          ? const Center(child: Text("No purchase history available"))
          : ListView.separated(
              itemCount: history.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final item = history[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  title: Text(
                    item['product'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Qty: ${item['quantity']} • ${item['date']}"),
                  trailing: Text(
                    "\$${item['amount'].toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
