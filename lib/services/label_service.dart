import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/part.dart';
import '../utils/formatters.dart';

/// Generates printable barcode labels for parts and rack/bin locations.
class LabelService {
  /// Print a sheet of barcode labels (Code-128) for the given parts.
  static Future<void> printPartLabels(List<Part> parts) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (ctx) => [
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: parts.map((p) => _label(p)).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (f) => doc.save());
  }

  static pw.Widget _label(Part p) {
    final code = (p.barcode == null || p.barcode!.isEmpty)
        ? p.partNumber.isEmpty
            ? p.id.substring(0, 8)
            : p.partNumber
        : p.barcode!;
    return pw.Container(
      width: 170,
      height: 90,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: .5)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p.name,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text('${p.brand} • ${p.binLocation}',
              style: const pw.TextStyle(fontSize: 7)),
          pw.SizedBox(height: 2),
          pw.Expanded(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: code,
              drawText: true,
              textStyle: const pw.TextStyle(fontSize: 7),
            ),
          ),
          pw.Text(Fmt.money(p.sellingPrice),
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
