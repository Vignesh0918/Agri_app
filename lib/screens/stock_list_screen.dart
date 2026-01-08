import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'stock_form_screen.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  List<Product> _allStock = [];
  List<Product> _filteredStock = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ProductService.getProducts();
      if (mounted) {
        setState(() {
          _allStock = products;
          _filteredStock = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load stock: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredStock = _allStock
          .where(
            (item) => item.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  Future<void> _deleteItem(int productId) async {
    final success = await ProductService.deleteProduct(productId);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
        _fetchProducts(); // Refresh list
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete item')));
      }
    }
  }

  void _showQuickAddDialog(Product item) {
    final TextEditingController quantityController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Quantity: ${item.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Current Quantity: ${item.stockQuantity}"),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Additional Quantity",
                border: OutlineInputBorder(),
                hintText: "Enter amount to add",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final int? toAdd = int.tryParse(quantityController.text);
              if (toAdd != null && toAdd > 0) {
                Navigator.pop(ctx);
                final updated = await ProductService.updateStock(
                  item.id,
                  toAdd,
                );
                if (updated != null) {
                  _fetchProducts(); // Refresh
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Updated ${item.name}. New Qty: ${updated.stockQuantity}",
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a valid number")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search stock...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text("Stock List"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredStock.isEmpty
          ? Center(
              child: Text(
                _isSearching
                    ? "No items match your search."
                    : "No stock available.\nAdd new items using the button below.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchProducts,
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _filteredStock.length,
                itemBuilder: (context, index) {
                  final item = _filteredStock[index];
                  final bool isLowStock = item.stockQuantity < 10;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isLowStock
                          ? BorderSide(color: Colors.red.shade300, width: 1)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      onTap: () async {
                        final Map<String, dynamic> productMap = {
                          'id': item.id,
                          'name': item.name,
                          'quantity': item.stockQuantity,
                          'price': item.unitPrice,
                          'supplier': item.supplierName,
                          'category': item.category,
                        };
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StockFormScreen(product: productMap),
                          ),
                        );
                        if (result == true) _fetchProducts();
                      },
                      leading: CircleAvatar(
                        backgroundColor: isLowStock
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        child: Icon(
                          isLowStock ? Icons.warning_amber : Icons.inventory_2,
                          color: isLowStock
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "Qty: ${item.stockQuantity}",
                                style: TextStyle(
                                  color: isLowStock
                                      ? Colors.red
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Price: ₹${item.unitPrice.toStringAsFixed(2)}",
                              ),
                            ],
                          ),
                          if (item.supplierName != null &&
                              item.supplierName!.isNotEmpty)
                            Text(
                              "Supplier: ${item.supplierName}",
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Color(0xFF2E7D32),
                              size: 28,
                            ),
                            onPressed: () {
                              _showQuickAddDialog(item);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Delete Item?"),
                                  content: Text(
                                    "Are you sure you want to delete '${item.name}'?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _deleteItem(item.id);
                                      },
                                      child: const Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StockFormScreen()),
          );
          if (result == true) _fetchProducts();
        },
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
