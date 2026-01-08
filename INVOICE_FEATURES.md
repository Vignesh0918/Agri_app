# Invoice & GST Feature Documentation

## Overview
This document describes the new invoicing and GST calculation features added to the Agriculture Shop Manager application.

## Features Added

### 1. **GST Calculation on Sales**
When recording a sale, the app now:
- Allows selection of GST rate (0%, 5%, 12%, 18%, 28%)
- Automatically calculates:
  - Base Price (quantity × unit price)
  - GST Amount (base price × GST percentage)
  - Total Price (base price + GST amount)
- Displays a clear breakdown showing all three components

### 2. **Automatic Invoice Generation**
For every sale transaction:
- A unique invoice number is automatically generated
  - Format: `INV-YYYYMM-XXXX`
  - Example: `INV-202512-1001`
- Invoice includes:
  - Invoice number
  - Date of sale
  - Customer name and phone
  - Item details (name, quantity, unit price)
  - Price breakdown (base price, GST %, GST amount, total)

### 3. **Invoice History & Management**
A dedicated Invoice History screen provides:
- **Summary Statistics**:
  - Total Sales Amount
  - Total GST Collected
  - Total Number of Invoices

- **Search Functionality**:
  - Search by Customer Name
  - Search by Invoice Number
  - Toggle between search types

- **Invoice List**:
  - Chronological list of all invoices
  - Shows key information at a glance
  - Tap any invoice to view full details

### 4. **Detailed Invoice View**
Each invoice can be viewed in detail with:
- Professional invoice layout
- Complete customer information
- Itemized breakdown
- GST calculation details
- Share and Print buttons (ready for future implementation)

## How to Use

### Recording a Sale with GST

1. Navigate to **Dashboard** → **Daily Transactions** → **Record Sale**
2. Fill in the sale details:
   - Date
   - Customer Name
   - Phone Number
   - Product Name
   - Quantity
   - Unit Price
3. **Select GST Rate** from the available options (0%, 5%, 12%, 18%, 28%)
4. Review the price breakdown showing:
   - Base Price
   - GST Amount
   - Total Amount
5. Click **Save Sale**
6. An invoice will be automatically generated and the invoice number will be displayed in the success message

### Viewing Invoice History

1. From the **Dashboard**, tap on **Invoice History**
2. View summary statistics at the top
3. Use the search functionality:
   - Toggle between "Customer" or "Invoice #" search
   - Type in the search box to filter results
4. Tap on any invoice card to view full details

### Viewing Invoice Details

1. From the Invoice History screen, tap on any invoice
2. View complete invoice information including:
   - Invoice number and date
   - Customer details
   - Item details
   - Complete price breakdown with GST
3. Use the Share or Print buttons (functionality coming soon)

## Technical Details

### New Models

#### Invoice Model (`lib/models/invoice.dart`)
```dart
class Invoice {
  final String invoiceNumber;
  final DateTime dateOfSale;
  final String customerName;
  final String customerPhone;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double basePrice;
  final double gstPercentage;
  final double gstAmount;
  final double totalPrice;
}
```

#### Updated TransactionRecord Model
Now includes:
- `basePrice` - Price without GST
- `gstPercentage` - GST rate applied
- `gstAmount` - Calculated GST
- `invoiceNumber` - Reference to generated invoice (for sales only)

### New Services

#### InvoiceService (`lib/services/invoice_service.dart`)
Manages all invoice operations:
- `generateInvoiceNumber()` - Creates unique invoice numbers
- `addInvoice()` - Stores new invoices
- `searchByCustomer()` - Search invoices by customer name
- `searchByInvoiceNumber()` - Search by invoice number
- `getTotalSales()` - Calculate total sales amount
- `getTotalGSTCollected()` - Calculate total GST collected

### New Screens

1. **Invoice Detail Screen** (`lib/screens/invoices/invoice_detail_screen.dart`)
   - Professional invoice display
   - Share and print actions

2. **Invoice History Screen** (`lib/screens/invoices/invoice_history_screen.dart`)
   - Summary statistics
   - Search functionality
   - Invoice list with filtering

### Updated Screens

1. **Add Transaction Screen** (`lib/screens/transactions/add_transaction_screen.dart`)
   - GST rate selector (for sales only)
   - Price breakdown display
   - Automatic invoice generation

2. **Dashboard Screen** (`lib/screens/dashboard_screen.dart`)
   - New "Invoice History" navigation button

## Data Storage

Currently, all invoice data is stored in-memory using the singleton pattern. This means:
- ✅ Fast access and operations
- ✅ No database setup required
- ⚠️ Data is lost when the app is closed
- 💡 Future enhancement: Add persistent storage (SQLite/Firebase)

## GST Rates

The app supports the following GST rates (common in India):
- **0%** - Exempt items
- **5%** - Essential goods
- **12%** - Standard goods
- **18%** - Most goods and services (default)
- **28%** - Luxury items

## Currency

The app uses the Indian Rupee (₹) symbol for all monetary values.

## Future Enhancements

Potential improvements for future versions:
1. **PDF Generation** - Generate PDF invoices for sharing/printing
2. **Email Integration** - Email invoices directly to customers
3. **Persistent Storage** - Save invoices to database
4. **Advanced Filtering** - Filter by date range, amount range, etc.
5. **Invoice Templates** - Customizable invoice designs
6. **Tax Reports** - Generate GST reports for tax filing
7. **Multi-item Invoices** - Support multiple items per invoice
8. **Payment Tracking** - Track paid/unpaid status

## Notes

- GST calculation is only applied to **Sales** transactions, not Purchases
- Invoice numbers are auto-incremented and unique
- All monetary calculations use 2 decimal places
- Search is case-insensitive for better user experience
