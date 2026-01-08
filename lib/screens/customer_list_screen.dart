import 'package:flutter/material.dart';
import 'add_customer_screen.dart';
import 'customer_history_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  // Dummy in-memory data
  final List<Map<String, dynamic>> _customers = [
    {'id': 1, 'name': 'John Doe', 'phone': '+91 98765 43210'},
    {'id': 2, 'name': 'Alice Smith', 'phone': '+91 87654 32109'},
    {'id': 3, 'name': 'Robert Brown', 'phone': '+91 76543 21098'},
    {'id': 4, 'name': 'Maria Garcia', 'phone': '+91 65432 10987'},
    {'id': 5, 'name': 'James Wilson', 'phone': '+91 54321 09876'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers"),
        backgroundColor: const Color(0xFFE65100), // Orange 900
        foregroundColor: Colors.white,
      ),
      body: _customers.isEmpty
          ? const Center(child: Text("No customers found."))
          : ListView.builder(
              itemCount: _customers.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final customer = _customers[index];
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
                      backgroundColor: Colors.orange.shade100,
                      child: Text(
                        customer['name'][0],
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      customer['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(customer['phone']),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CustomerHistoryScreen(customer: customer),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          );

          if (result != null && result is Map<String, dynamic>) {
            setState(() {
              _customers.insert(0, result);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Customer '${result['name']}' added.")),
            );
          }
        },
        backgroundColor: const Color(0xFFE65100),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
