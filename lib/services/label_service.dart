import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/part.dart';
import '../utils/formatters.dart';

enum LabelStyle { productBarcode, shelfBinTag, priceSticker }

/// Generates printable barcode & QR labels with multiple layouts.
class LabelService {
  /// Print single part label with customizable quantity.
  static Future<void> printSinglePartLabel(
    Part part, {
    int copies = 1,
    LabelStyle style = LabelStyle.productBarcode,
  }) async {
    final list = List.filled(copies, part);
    await printCustomLabels(list, style: style);
  }

  /// Print custom label sheet.
  static Future<void> printCustomLabels(
    List<Part> parts, {
    LabelStyle style = LabelStyle.productBarcode,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (ctx) => [
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: parts.map((p) => _renderLabel(p, style)).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => doc.save(),
      name: 'PitStock_Labels_${style.name}.pdf',
    );
  }

  static pw.Widget _renderLabel(Part p, LabelStyle style) {
    switch (style) {
      case LabelStyle.productBarcode:
        return _productLabel(p);
      case LabelStyle.shelfBinTag:
        return _shelfBinTag(p);
      case LabelStyle.priceSticker:
        return _priceSticker(p);
    }
  }

  static pw.Widget _productLabel(Part p) {
    final code = (p.barcode != null && p.barcode!.isNotEmpty)
        ? p.barcode!
        : (p.partNumber.isNotEmpty ? p.partNumber : p.id.substring(0, 8));
    return pw.Container(
      width: 175,
      height: 95,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5, color: PdfColors.grey700),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p.name,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                  fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
          pw.Text('${p.brand} • ${p.binLocation}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Expanded(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: code,
              drawText: true,
              textStyle: const pw.TextStyle(fontSize: 6.5),
            ),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(p.fitment,
                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
              pw.Text('MRP: Rs ${p.sellingPrice.toStringAsFixed(0)}',
                  style: pw.TextStyle(
                      fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _shelfBinTag(Part p) {
    final code = (p.barcode != null && p.barcode!.isNotEmpty)
        ? p.barcode!
        : (p.partNumber.isNotEmpty ? p.partNumber : p.id.substring(0, 8));
    return pw.Container(
      width: 260,
      height: 120,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1.5, color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue900,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text('LOCATION: ${p.binLocation}',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold)),
                ),
                pw.Text(p.name,
                    maxLines: 2,
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('${p.brand} • ${p.partNumber}',
                    style: const pw.TextStyle(fontSize: 8)),
                pw.Text('MRP: Rs ${p.sellingPrice.toStringAsFixed(0)} (Inc GST)',
                    style: pw.TextStyle(
                        fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(width: 6),
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: code,
            width: 75,
            height: 75,
          ),
        ],
      ),
    );
  }

  static pw.Widget _priceSticker(Part p) {
    return pw.Container(
      width: 130,
      height: 60,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5, color: PdfColors.grey500),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(p.name,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
          pw.Text(p.brand, style: const pw.TextStyle(fontSize: 6.5)),
          pw.SizedBox(height: 2),
          pw.Text('Rs ${p.sellingPrice.toStringAsFixed(0)}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text('Loc: ${p.binLocation}',
              style: const pw.TextStyle(fontSize: 6)),
        ],
      ),
    );
  }
}
