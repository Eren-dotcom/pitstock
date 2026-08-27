import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/invoice.dart';
import '../utils/formatters.dart';

/// Generates professional GST-compliant invoice PDFs and prints/shares them.
class InvoiceService {
  static Future<void> printInvoice({
    required Invoice invoice,
    required String shopName,
    String? shopGstin,
    String? shopPhone,
    String? shopAddress,
    String? upiId,
    String? footerTerms,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(shopName,
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      if (shopAddress != null && shopAddress.isNotEmpty)
                        pw.Text(shopAddress,
                            style: const pw.TextStyle(fontSize: 8.5)),
                      if (shopPhone != null && shopPhone.isNotEmpty)
                        pw.Text('Phone: $shopPhone',
                            style: const pw.TextStyle(fontSize: 8.5)),
                      if (shopGstin != null && shopGstin.isNotEmpty)
                        pw.Text('GSTIN: $shopGstin',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue900,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text('TAX INVOICE',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Invoice No: ${invoice.number}',
                        style: pw.TextStyle(
                            fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${Fmt.date(invoice.createdAt)}',
                        style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text('Payment: ${invoice.paymentMethod.label}',
                        style: const pw.TextStyle(fontSize: 8.5)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 6),

            // Bill To details
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CUSTOMER DETAILS',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text(invoice.customerName,
                          style: pw.TextStyle(
                              fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      if (invoice.customerPhone != null &&
                          invoice.customerPhone!.isNotEmpty)
                        pw.Text('Phone: ${invoice.customerPhone}',
                            style: const pw.TextStyle(fontSize: 8.5)),
                      if (invoice.customerGstin != null &&
                          invoice.customerGstin!.isNotEmpty)
                        pw.Text('GSTIN: ${invoice.customerGstin}',
                            style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                  if (invoice.vehicleReg != null ||
                      invoice.vehicleInfo != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('VEHICLE DETAILS',
                            style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        if (invoice.vehicleReg != null)
                          pw.Text(invoice.vehicleReg!,
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold)),
                        if (invoice.vehicleInfo != null)
                          pw.Text(invoice.vehicleInfo!,
                              style: const pw.TextStyle(fontSize: 8.5)),
                      ],
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Line items table
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Item & Description', 'Qty', 'Rate (₹)', 'GST%', 'Core (₹)', 'Amount (₹)'],
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              data: List.generate(invoice.lines.length, (i) {
                final l = invoice.lines[i];
                return [
                  '${i + 1}',
                  l.name + (l.isLabour ? ' (Labour / Service)' : (l.partNumber.isNotEmpty ? ' • ${l.partNumber}' : '')),
                  '${l.quantity}',
                  l.unitPrice.toStringAsFixed(2),
                  '${l.gstPercent.toStringAsFixed(0)}%',
                  l.coreAmount > 0 ? l.coreAmount.toStringAsFixed(0) : '—',
                  l.total.toStringAsFixed(2),
                ];
              }),
            ),
            pw.SizedBox(height: 10),

            // Summary Totals & QR code
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // UPI Payment QR & Note
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (upiId != null && upiId.isNotEmpty) ...[
                        pw.Text('Pay via UPI:',
                            style: pw.TextStyle(
                                fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(shopName)}&am=${invoice.grandTotal.toStringAsFixed(2)}&cu=INR',
                          width: 65,
                          height: 65,
                        ),
                        pw.Text('UPI ID: $upiId',
                            style: const pw.TextStyle(fontSize: 7.5)),
                      ],
                    ],
                  ),
                ),
                // Totals box
                pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      _totRow('Subtotal', invoice.subtotal),
                      if (invoice.discountAmount > 0)
                        _totRow('Discount', -invoice.discountAmount, isDiscount: true),
                      _totRow('CGST (${(invoice.gstTotal > 0 ? '9%' : '0%')})', invoice.cgstTotal),
                      _totRow('SGST (${(invoice.gstTotal > 0 ? '9%' : '0%')})', invoice.sgstTotal),
                      if (invoice.coreTotal > 0)
                        _totRow('Core Deposit', invoice.coreTotal),
                      pw.Divider(thickness: 1, color: PdfColors.grey400),
                      _totRow('GRAND TOTAL', invoice.grandTotal, bold: true),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),

            // Terms and Signature
            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Terms & Conditions:',
                          style: pw.TextStyle(
                              fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        footerTerms ??
                            '1. Goods once sold will not be taken back without bill.\n'
                            '2. Core deposit refundable within 7 days with old undamaged part.',
                        style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('For $shopName',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 24),
                    pw.Text('Authorised Signatory',
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => doc.save(),
      name: '${invoice.number.replaceAll('/', '_')}.pdf',
    );
  }

  static pw.Widget _totRow(String label, double v,
      {bool bold = false, bool isDiscount = false}) {
    final style = pw.TextStyle(
        fontSize: bold ? 10 : 8.5,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: isDiscount ? PdfColors.green700 : (bold ? PdfColors.blue900 : PdfColors.black));
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text('Rs ${v.abs().toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
