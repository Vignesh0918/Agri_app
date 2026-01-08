import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/invoice.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    // Load fonts or standard fonts
    // final font = await PdfGoogleFonts.nunitoExtraLight();
    // keeping it simple with standard fonts for offline capability if needed

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 40,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.Text(
                      invoice.invoiceNumber,
                      style: const pw.TextStyle(
                        fontSize: 20,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Date & Customer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Billed To:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        invoice.customerName,
                        style: const pw.TextStyle(fontSize: 18),
                      ),
                      pw.Text(invoice.customerPhone),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        DateFormat('MMM dd, yyyy').format(invoice.dateOfSale),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Items Table
              pw.TableHelper.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.green700,
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                headers: <String>['Item', 'Quantity', 'Unit Price', 'Total'],
                data: <List<String>>[
                  [
                    invoice.itemName,
                    '${invoice.quantity}',
                    '${invoice.unitPrice.toStringAsFixed(2)}',
                    '${invoice.basePrice.toStringAsFixed(2)}',
                  ],
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),

              // Totals
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.SizedBox(height: 10),
                    _buildPdfPriceRow('Subtotal', invoice.basePrice),
                    _buildPdfPriceRow(
                      'GST (${invoice.gstPercentage.toInt()}%)',
                      invoice.gstAmount,
                    ),
                    pw.Divider(),
                    _buildPdfPriceRow(
                      'Total Amount',
                      invoice.totalPrice,
                      isBold: true,
                      fontSize: 18,
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: const pw.TextStyle(color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfPriceRow(
    String label,
    double amount, {
    bool isBold = false,
    double fontSize = 14,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Text(
          '${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Invoice',
            onPressed: () async {
              await Printing.sharePdf(
                bytes: await _generatePdf(PdfPageFormat.a4),
                filename: 'invoice_${invoice.invoiceNumber}.pdf',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Invoice',
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => _generatePdf(format),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2E7D32),
                    const Color(0xFF2E7D32).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INVOICE',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Section
                  _buildSectionCard(
                    icon: Icons.calendar_today,
                    title: 'Date of Sale',
                    content: DateFormat(
                      'MMMM dd, yyyy',
                    ).format(invoice.dateOfSale),
                  ),
                  const SizedBox(height: 16),

                  // Customer Details
                  _buildSectionCard(
                    icon: Icons.person,
                    title: 'Customer Details',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              invoice.customerPhone,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Item Details
                  _buildSectionCard(
                    icon: Icons.inventory_2,
                    title: 'Item Details',
                    content: Column(
                      children: [
                        _buildDetailRow('Product', invoice.itemName),
                        const Divider(height: 20),
                        _buildDetailRow(
                          'Quantity',
                          '${invoice.quantity} units',
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          'Unit Price',
                          '₹${invoice.unitPrice.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price Breakdown
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade50, Colors.green.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'PRICE BREAKDOWN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildPriceRow(
                          'Base Price',
                          invoice.basePrice,
                          Colors.black87,
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow(
                          'GST (${invoice.gstPercentage.toInt()}%)',
                          invoice.gstAmount,
                          Colors.orange.shade700,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(thickness: 2),
                        ),
                        _buildPriceRow(
                          'TOTAL AMOUNT',
                          invoice.totalPrice,
                          const Color(0xFF2E7D32),
                          isBold: true,
                          fontSize: 22,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Thank you for your business!',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required dynamic content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2E7D32), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content is String
              ? Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : content,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
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
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: fontSize + 2,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
