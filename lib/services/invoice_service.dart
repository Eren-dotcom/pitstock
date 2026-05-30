import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/work_order.dart';
import '../utils/formatters.dart';

/// Generates GST-compliant invoice PDFs and prints them.
class InvoiceService {
  static Future<void> printInvoice({
    required String invoiceNumber,
    required String shopName,
    String? shopGstin,
    required String customerName,
    String? customerPhone,
    String? vehicleReg,
    required List<WorkOrderLine> lines,
  }) async {
    final doc = pw.Document();

    final subtotal = lines.fold(0.0, (s, l) => s + l.lineSubtotal);
    final cgst = lines.fold(0.0, (s, l) => s + l.lineGst) / 2;
    final sgst = cgst;
    final core = lines.fold(0.0, (s, l) => s + l.lineCore);
    final grand = lines.fold(0.0, (s, l) => s + l.lineTotal);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(shopName,
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    if (shopGstin != null) pw.Text('GSTIN: $shopGstin'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TAX INVOICE',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('No: $invoiceNumber'),
                    pw.Text(Fmt.date(DateTime.now())),
                  ],
                ),
              ],
            ),
            pw.Divider(),
            pw.Text('Bill To: $customerName'),
            if (customerPhone != null) pw.Text('Phone: $customerPhone'),
            if (vehicleReg != null) pw.Text('Vehicle: $vehicleReg'),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['Item', 'Qty', 'Rate', 'GST%', 'Core', 'Amount'],
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              data: lines
                  .map((l) => [
                        l.name + (l.isLabour ? ' (Labour)' : ''),
                        '${l.quantity}',
                        l.price.toStringAsFixed(2),
                        '${l.gstPercent.toStringAsFixed(0)}%',
                        l.lineCore.toStringAsFixed(0),
                        l.lineTotal.toStringAsFixed(2),
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 220,
                child: pw.Column(children: [
                  _totRow('Subtotal', subtotal),
                  _totRow('CGST', cgst),
                  _totRow('SGST', sgst),
                  if (core > 0) _totRow('Core Charge', core),
                  pw.Divider(),
                  _totRow('GRAND TOTAL', grand, bold: true),
                ]),
              ),
            ),
            pw.Spacer(),
            pw.Text(
                'Note: Core charges are refundable on return of the old part.',
                style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 20),
            pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Authorised Signatory')),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (f) => doc.save());
  }

  static pw.Widget _totRow(String label, double v, {bool bold = false}) {
    final style = pw.TextStyle(
        fontSize: bold ? 12 : 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text('Rs ${v.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
