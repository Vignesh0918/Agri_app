import 'package:flutter/material.dart';
import '../../models/transaction_record.dart';
import '../../services/transaction_service.dart';
import '../../services/product_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType type;

  const AddTransactionScreen({super.key, required this.type});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  double _basePrice = 0.0;
  double _gstPercentage = 18.0; // Default GST 18%
  double _gstAmount = 0.0;
  double _totalAmount = 0.0;
  String _selectedUnit = "kg";

  bool get _isSale => widget.type == TransactionType.sale;

  // Common GST rates in India
  final List<double> _gstRates = [0, 5, 12, 18, 28];

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final qty = double.tryParse(_quantityController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    setState(() {
      _basePrice = qty * price;

      // Only calculate GST for sales
      if (_isSale) {
        _gstAmount = _basePrice * (_gstPercentage / 100);
        _totalAmount = _basePrice + _gstAmount;
      } else {
        _gstAmount = 0.0;
        _totalAmount = _basePrice;
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveContactToDevice(String name, String phone) async {
    try {
      // 1. Check/Request Permissions
      if (await FlutterContacts.requestPermission()) {
        // 2. Check if contact already exists
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );

        // Simple normalization for checking duplicates (removes non-digits)
        final normalizedNewPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

        bool exists = contacts.any(
          (c) => c.phones.any((p) {
            final normalizedExisting = p.number.replaceAll(
              RegExp(r'[^\d+]'),
              '',
            );
            return normalizedExisting.contains(normalizedNewPhone) ||
                normalizedNewPhone.contains(normalizedExisting);
          }),
        );

        if (!exists) {
          // 3. Create new Contact
          final newContact = Contact()
            ..name.first = name
            ..phones = [Phone(phone)];

          await newContact.insert();
          print('✅ Contact saved to device: $name ($phone)');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Contact "$name" saved to device!')),
            );
          }
        } else {
          print('ℹ️ Contact already exists, skipping save.');
        }
      } else {
        print('❌ Contact permission denied');
      }
    } catch (e) {
      print('❌ Failed to save contact: $e');
    }
  }

  void _saveTransaction() async {
    // Made async
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final productNameInput = _productController.text.trim();
      final quantity = double.parse(_quantityController.text);
      final price = double.parse(_priceController.text);

      // Save contact to device automatically
      await _saveContactToDevice(name, phone);

      // --- 1. Find Correct Product Name (Case-Insensitive) ---
      // We do this to ensure the backend finds the product and updates stock.
      String canonicalProductName = productNameInput;
      try {
        final products = await ProductService.getProducts(
          search: productNameInput,
        );
        final product = products.firstWhere(
          (p) => p.name.toLowerCase() == productNameInput.toLowerCase(),
          orElse: () {
            if (products.length == 1) return products.first;
            return products.isNotEmpty
                ? products.first
                : throw Exception("Product not found");
          },
        );
        canonicalProductName = product.name;
      } catch (e) {
        print('Using input product name: $productNameInput. Reason: $e');
      }

      // --- 2. Record Transaction (Backend handles Stock, Invoice, Customer) ---
      final record = TransactionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
        type: widget.type,
        partyName: name,
        phoneNumber: phone,
        productName: canonicalProductName,
        quantity: quantity,
        unitPrice: price,
        basePrice: _basePrice,
        gstPercentage: _isSale ? _gstPercentage : 0.0,
        gstAmount: _isSale ? _gstAmount : 0.0,
        totalAmount: _totalAmount,
        date: _selectedDate,
        quantityUnit: _selectedUnit,
      );

      // Using createTransaction directly since it returns Future, unlike the void wrapper
      final createdTransaction = await TransactionService().createTransaction(
        record,
      );

      if (mounted) {
        final invoiceNum = createdTransaction?.invoiceNumber;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSale
                  ? 'Sale Recorded Successfully\nInvoice: ${invoiceNum ?? "Generated"}'
                  : 'Purchase Recorded Successfully',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _isSale ? const Color(0xFF2E7D32) : Colors.blue.shade800;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSale ? "Record Sale" : "Record Purchase"),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate),
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Party Name (Customer or Supplier)
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _isSale ? 'Customer Name' : 'Supplier Name',
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (!RegExp(r'^[0-9+]+$').hasMatch(value)) {
                    return 'Enter a valid numeric phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Product Name
              TextFormField(
                controller: _productController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Quantity & Price
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 15,
                        ),
                      ),
                      items: ["kg", "L"].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedUnit = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Price / Unit',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // GST Selection (Only for Sales)
              if (_isSale) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GST Rate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _gstRates.map((rate) {
                          final isSelected = _gstPercentage == rate;
                          return ChoiceChip(
                            label: Text('${rate.toInt()}%'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _gstPercentage = rate;
                                _calculateTotal();
                              });
                            },
                            selectedColor: themeColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Price Breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildPriceRow(
                      'Base Price:',
                      _basePrice,
                      themeColor,
                      isBold: false,
                    ),
                    if (_isSale && _gstPercentage > 0) ...[
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        'GST (${_gstPercentage.toInt()}%):',
                        _gstAmount,
                        Colors.orange.shade700,
                        isBold: false,
                      ),
                      const Divider(height: 24),
                    ],
                    _buildPriceRow(
                      'Total Amount:',
                      _totalAmount,
                      themeColor,
                      isBold: true,
                      fontSize: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isSale ? "Save Sale" : "Save Purchase",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
    double fontSize = 16,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: fontSize + 2,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
