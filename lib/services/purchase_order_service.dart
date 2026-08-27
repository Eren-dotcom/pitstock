import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/supplier.dart';
import '../utils/formatters.dart';

/// Generates printable Purchase Order PDFs for vendors.
class PurchaseOrderService {
  static Future<void> printPurchaseOrder({
    required PurchaseOrder po,
    Supplier? supplier,
    required String shopName,
    String? shopGstin,
    String? shopPhone,
    String? shopAddress,
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
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(shopName,
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    if (shopAddress != null)
                      pw.Text(shopAddress,
                          style: const pw.TextStyle(fontSize: 8.5)),
                    if (shopPhone != null)
                      pw.Text('Phone: $shopPhone',
                          style: const pw.TextStyle(fontSize: 8.5)),
                    if (shopGstin != null)
                      pw.Text('GSTIN: $shopGstin',
                          style: const pw.TextStyle(fontSize: 8.5)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal900,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('PURCHASE ORDER',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text(po.orderNumber,
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 6),

            // Vendor details
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('VENDOR / SUPPLIER:',
                        style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700)),
                    pw.Text(po.supplierName,
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    if (supplier != null && supplier.phone.isNotEmpty)
                      pw.Text('Phone: ${supplier.phone}',
                          style: const pw.TextStyle(fontSize: 8.5)),
                    if (supplier != null && supplier.gstin != null)
                      pw.Text('GSTIN: ${supplier.gstin}',
                          style: const pw.TextStyle(fontSize: 8.5)),
                    if (supplier != null && supplier.address != null)
                      pw.Text(supplier.address!,
                          style: const pw.TextStyle(fontSize: 8.5)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('PO Date: ${Fmt.date(po.createdAt)}',
                        style: const pw.TextStyle(fontSize: 8.5)),
                    if (po.expectedDate != null)
                      pw.Text('Expected: ${Fmt.date(po.expectedDate!)}',
                          style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text('Status: ${po.status.label}',
                        style: pw.TextStyle(
                            fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    if (supplier != null && supplier.paymentTerms != null)
                      pw.Text('Terms: ${supplier.paymentTerms}',
                          style: const pw.TextStyle(fontSize: 8.5)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Table of items
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Part Name / Description', 'Part No', 'Qty', 'Unit Cost (₹)', 'Tax%', 'Total (₹)'],
              headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              data: List.generate(po.lines.length, (i) {
                final l = po.lines[i];
                return [
                  '${i + 1}',
                  l.name,
                  l.partNumber.isNotEmpty ? l.partNumber : '—',
                  '${l.quantity}',
                  l.unitCost.toStringAsFixed(2),
                  '${l.taxPercent.toStringAsFixed(0)}%',
                  l.total.toStringAsFixed(2),
                ];
              }),
            ),
            pw.SizedBox(height: 10),

            // Totals
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 200,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    _row('Subtotal', po.subtotal),
                    _row('Tax Total', po.taxTotal),
                    pw.Divider(),
                    _row('GRAND TOTAL', po.grandTotal, bold: true),
                  ],
                ),
              ),
            ),
            if (po.notes != null && po.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text('Notes / Instructions:',
                  style: pw.TextStyle(
                      fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              pw.Text(po.notes!, style: const pw.TextStyle(fontSize: 8)),
            ],
            pw.Spacer(),

            // Authorisation
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by PitStock AI Inventory',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Authorized Signature',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 20),
                    pw.Container(width: 120, height: 1, color: PdfColors.black),
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
      name: 'PO_${po.orderNumber}.pdf',
    );
  }

  static pw.Widget _row(String label, double val, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text('Rs ${val.toStringAsFixed(2)}',
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
