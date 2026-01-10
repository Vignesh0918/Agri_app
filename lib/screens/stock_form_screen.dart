import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class StockFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const StockFormScreen({super.key, this.product});

  @override
  State<StockFormScreen> createState() => _StockFormScreenState();
}

class _StockFormScreenState extends State<StockFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _supplierController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?['name'] ?? '');
    _quantityController = TextEditingController(
      text: p?['quantity']?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: p?['price']?.toString() ?? '',
    );
    _supplierController = TextEditingController(text: p?['supplier'] ?? '');

    if (p?['expiry'] != null) {
      try {
        _selectedDate = DateFormat('yyyy-MM-dd').parse(p!['expiry']);
      } catch (e) {
        // Handle parse error or ignore
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveStock() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an expiry date')),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final isEditing = widget.product != null;
        final productId = isEditing ? widget.product!['id'] as int : 0;

        final product = Product(
          id: productId,
          name: _nameController.text,
          description: '',
          category: widget.product?['category'] ?? 'Seeds',
          unitPrice: double.parse(_priceController.text),
          stockQuantity: double.parse(_quantityController.text),
          minStockLevel: 5,
          supplierName: _supplierController.text,
          supplierContact: '',
          isActive: true,
          createdAt: DateTime.now(),
        );

        final result = isEditing
            ? await ProductService.updateProduct(productId, product)
            : await ProductService.createProduct(product);

        // Hide loading indicator
        if (mounted) Navigator.pop(context);

        if (result != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing
                      ? 'Stock Updated Successfully'
                      : 'Stock Saved Successfully',
                ),
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('Failed to save product');
        }
      } catch (e) {
        // Hide loading indicator if error
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.product != null;

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
          isEditing ? "Edit Product" : "New Product",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Name
              _buildFieldLabel("Product Details"),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Urea Fertilizer',
                  prefixIcon: Icon(Icons.inventory_2_rounded, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Quantity & Price Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("Stock Quantity"),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '0.0',
                            prefixIcon: Icon(Icons.numbers_rounded, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (double.tryParse(value) == null || double.parse(value) < 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("Unit Price (₹)"),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (double.tryParse(value) == null || double.parse(value) < 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Expiry Date
              _buildFieldLabel("Expiry Date"),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? 'Select Expiry Date'
                            : DateFormat('MMMM dd, yyyy').format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null ? Colors.grey[400] : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Supplier Name
              _buildFieldLabel("Supplier"),
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  hintText: 'e.g. AgriCorp India',
                  prefixIcon: Icon(Icons.local_shipping_rounded, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter supplier name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),

              // Save Button
              ElevatedButton(
                onPressed: _saveStock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isEditing ? Icons.check_rounded : Icons.add_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? "Update Inventory" : "Add to Inventory",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF444444),
        ),
      ),
    );
  }
}
