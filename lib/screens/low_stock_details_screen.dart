import 'package:flutter/material.dart';
import '../../services/data_service.dart';

class LowStockDetailsScreen extends StatefulWidget {
  const LowStockDetailsScreen({super.key});

  @override
  State<LowStockDetailsScreen> createState() => _LowStockDetailsScreenState();
}

class _LowStockDetailsScreenState extends State<LowStockDetailsScreen> {
  final DataService _dataService = DataService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Low Stock Items"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: _dataService.getDashboardStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.lowStockProducts.isEmpty) {
            return const Center(child: Text("No low stock items found."));
          }

          final lowStockList = snapshot.data!.lowStockProducts;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lowStockList.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = lowStockList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  child: Icon(Icons.warning_amber, color: Colors.red.shade700),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${item.quantity} left",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
