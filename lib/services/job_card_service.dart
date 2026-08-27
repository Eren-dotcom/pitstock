import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/work_order.dart';
import '../utils/formatters.dart';

/// Generates printable workshop Job Card sheets for mechanic clipboards.
class JobCardService {
  static Future<void> printJobCard({
    required WorkOrder workOrder,
    required String shopName,
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
            // Workshop Header
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
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange900,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('GARAGE JOB CARD',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text(workOrder.number,
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 6),

            // Customer & Vehicle Info Grid
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                          child: _infoCell('CUSTOMER NAME', workOrder.customerName)),
                      pw.Expanded(
                          child: _infoCell('CONTACT PHONE', workOrder.customerPhone ?? '—')),
                      pw.Expanded(
                          child: _infoCell('VEHICLE REG NO', workOrder.vehicleReg ?? '—', bold: true)),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(
                          child: _infoCell('VEHICLE MODEL', workOrder.vehicleInfo ?? '—')),
                      pw.Expanded(
                          child: _infoCell('ODOMETER (KM)', workOrder.odometer != null ? '${workOrder.odometer} km' : '—')),
                      pw.Expanded(
                          child: _infoCell('FUEL LEVEL', workOrder.fuelLevel ?? '—')),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(
                          child: _infoCell('ASSIGNED MECHANIC', workOrder.technician ?? 'Unassigned')),
                      pw.Expanded(
                          child: _infoCell('DATE IN', Fmt.date(workOrder.createdAt))),
                      pw.Expanded(
                          child: _infoCell('STATUS', workOrder.status.label)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Reported Complaints / Work Requested
            pw.Text('CUSTOMER COMPLAINTS / REQUESTED SERVICE:',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                (workOrder.complaints != null && workOrder.complaints!.isNotEmpty)
                    ? workOrder.complaints!
                    : 'Standard service & full vehicle inspection.',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.SizedBox(height: 12),

            // Parts & Labour Table
            pw.Text('PARTS & LABOUR ESTIMATE:',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Type', 'Description / Part No', 'Qty', 'Rate (₹)', 'Total (₹)'],
              headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              data: workOrder.lines.map((l) => [
                l.isLabour ? 'Labour' : 'Part',
                l.name + (l.partNumber.isNotEmpty ? ' (${l.partNumber})' : ''),
                '${l.quantity}',
                l.price.toStringAsFixed(2),
                l.lineTotal.toStringAsFixed(2),
              ]).toList(),
            ),
            pw.SizedBox(height: 8),

            // Grand Total
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text('Estimated Grand Total: Rs ${workOrder.grandTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
            ),
            pw.Spacer(),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Customer Authorization Signature:',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 24),
                    pw.Container(width: 140, height: 1, color: PdfColors.black),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Mechanic / Service Advisor Signature:',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 24),
                    pw.Container(width: 140, height: 1, color: PdfColors.black),
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
      name: 'JobCard_${workOrder.number}.pdf',
    );
  }

  static pw.Widget _infoCell(String title, String val, {bool bold = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
        pw.SizedBox(height: 1),
        pw.Text(val,
            style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }
}
