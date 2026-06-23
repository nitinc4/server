import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class InvoiceService {
  static Future<String?> generateAndDownloadInvoice(Map<String, dynamic> order) async {
    final pdf = pw.Document();

    final itemsList = order['items'] as List? ?? [];
    final address = order['shippingAddress'] as Map<String, dynamic>? ?? {};
    
    // Find seller details if any item has a seller
    Map<String, dynamic>? sellerDetails;
    for (var item in itemsList) {
      if (item['seller'] != null && item['seller']['name'] != null && item['seller']['name'].toString().isNotEmpty) {
        sellerDetails = Map<String, dynamic>.from(item['seller']);
        break;
      }
    }

    final String orderId = (order['_id'] ?? '').toString().toUpperCase();
    final String paymentMethod = order['paymentMethod'] ?? 'N/A';
    final String paymentStatus = order['paymentStatus'] ?? 'Pending';
    final String totalAmount = (order['totalAmount'] ?? 0).toDouble().toStringAsFixed(2);
    final String dateStr = order['createdAt'] != null
        ? order['createdAt'].toString().substring(0, 10)
        : '';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ZUDO INVOICE',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green800,
                          ),
                        ),
                        pw.Text('Platform GST: 29AABCZ1234D1Z5', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                      ]
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Order ID: #$orderId', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 8),

                // Customer & Seller details row
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Customer (Left)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Billed To:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text(address['name'] ?? 'Customer', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text(address['phone'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text(
                            '${address['address'] ?? ''}, ${address['city'] ?? ''}, ${address['state'] ?? ''} - ${address['pincode'] ?? ''}',
                            style: const pw.TextStyle(fontSize: 8),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    // Seller (Right)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Sold By:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          if (sellerDetails != null) ...[
                            pw.Text(sellerDetails['name'] ?? 'Seller', style: const pw.TextStyle(fontSize: 8)),
                            if (sellerDetails['phone'] != null)
                              pw.Text(sellerDetails['phone'].toString(), style: const pw.TextStyle(fontSize: 8)),
                            if (sellerDetails['address'] != null)
                              pw.Text(sellerDetails['address'].toString(), style: const pw.TextStyle(fontSize: 8), maxLines: 3),
                            if (sellerDetails['gstNumber'] != null)
                              pw.Text('GST No: ${sellerDetails['gstNumber']}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ] else ...[
                            pw.Text('Zudo Central Retail', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            pw.Text('GST No: 29AABCZ1234D1Z5', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            pw.Text('contact@zudo.com', style: const pw.TextStyle(fontSize: 8)),
                            pw.Text('Bengaluru, Karnataka, India', style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Items Table
                pw.Text('Order Summary', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Item Description', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Base Rate', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('GST %', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Tax', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                    ...itemsList.map((item) {
                      final double price = (item['price'] ?? 0).toDouble();
                      final int qty = (item['quantity'] ?? 0) as int;
                      final double gstPercent = (item['gstPercent'] ?? 0).toDouble();
                      final double gstAmount = (item['gstAmount'] ?? 0).toDouble();
                      final double baseRate = price - gstAmount;
                      final double itemTax = gstAmount * qty;
                      final double total = price * qty;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(item['name'] ?? 'Product', style: const pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Rs. ${baseRate.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('$qty', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('${gstPercent.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Rs. ${itemTax.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Rs. ${total.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Total & Payments Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Payment Method: $paymentMethod', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Status: $paymentStatus', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text('Grand Total: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs. $totalAmount', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                      ],
                    ),
                  ],
                ),
                pw.Spacer(),

                // Footer
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.Center(
                  child: pw.Text(
                    'Thank you for shopping with Zudo! This is a computer-generated invoice.',
                    style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    try {
      String path;
      if (Platform.isAndroid) {
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) {
          path = '${dir.path}/Invoice_$orderId.pdf';
        } else {
          final extDir = await getExternalStorageDirectory();
          path = '${extDir!.path}/Invoice_$orderId.pdf';
        }
      } else {
        final extDir = await getApplicationDocumentsDirectory();
        path = '${extDir.path}/Invoice_$orderId.pdf';
      }
      
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    } catch (e) {
      print('Error saving invoice: $e');
      return null;
    }
  }
}
