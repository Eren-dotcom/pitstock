import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/part.dart';
import '../utils/formatters.dart';

class ExportService {
  static Future<void> exportCsv(BuildContext context, List<Part> parts) async {
    final rows = <List<dynamic>>[
      [
        'Name', 'Part No', 'Brand', 'Category', 'Vehicle', 'Qty', 'Unit',
        'Cost', 'Selling', 'GST%', 'Barcode', 'Location', 'Stock Value'
      ],
      ...parts.map((p) => [
            p.name,
            p.partNumber,
            p.brand,
            p.category,
            [p.vehicleMake, p.vehicleModel].where((e) => e != null).join(' '),
            p.quantity,
            p.unit,
            p.costPrice,
            p.sellingPrice,
            p.gstPercent,
            p.barcode ?? '',
            p.location ?? '',
            p.stockValue,
          ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pitstock_inventory.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)],
        text: 'PitStock inventory export');
  }

  static Future<void> exportPdf(
      BuildContext context, List<Part> parts, String shopName) async {
    final doc = pw.Document();
    final totalValue = parts.fold(0.0, (s, p) => s + p.stockValue);
    final totalUnits = parts.fold(0, (s, p) => s + p.quantity);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
              level: 0,
              child: pw.Text('$shopName — Inventory Report',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold))),
          pw.Text('Generated: ${Fmt.date(DateTime.now())}'),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total SKUs: ${parts.length}'),
              pw.Text('Total Units: $totalUnits'),
              pw.Text('Stock Value: Rs ${totalValue.toStringAsFixed(0)}'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Brand', 'Cat', 'Qty', 'Sell', 'Value'],
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold),
            data: parts
                .map((p) => [
                      p.name,
                      p.brand,
                      p.category,
                      '${p.quantity}',
                      p.sellingPrice.toStringAsFixed(0),
                      p.stockValue.toStringAsFixed(0),
                    ])
                .toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (f) => doc.save());
  }
}
