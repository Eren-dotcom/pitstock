import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/part.dart';
import '../models/invoice.dart';
import '../models/stock_movement.dart';
import '../utils/formatters.dart';

class ExportService {
  /// Export inventory parts to CSV.
  static Future<void> exportCsv(BuildContext context, List<Part> parts) async {
    final rows = <List<dynamic>>[
      [
        'Name',
        'Part No',
        'Brand',
        'Category',
        'Type',
        'Vehicle Make',
        'Vehicle Model',
        'Qty',
        'Unit',
        'Min Stock',
        'Max Stock',
        'Cost Price',
        'Selling Price',
        'GST%',
        'Core Charge',
        'Barcode',
        'Shelf',
        'Bin',
        'Supplier',
        'Stock Value'
      ],
      ...parts.map((p) => [
            p.name,
            p.partNumber,
            p.brand,
            p.category,
            p.partType.label,
            p.vehicleMake ?? '',
            p.vehicleModel ?? '',
            p.quantity,
            p.unit,
            p.minStock,
            p.maxStock,
            p.costPrice,
            p.sellingPrice,
            p.gstPercent,
            p.coreCharge,
            p.barcode ?? '',
            p.shelf ?? '',
            p.bin ?? '',
            p.supplier ?? '',
            p.stockValue,
          ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pitstock_inventory.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)],
        text: 'PitStock inventory CSV export');
  }

  /// Export Sales Invoices to CSV.
  static Future<void> exportInvoicesCsv(
      BuildContext context, List<Invoice> invoices) async {
    final rows = <List<dynamic>>[
      [
        'Invoice No',
        'Date',
        'Customer Name',
        'Customer Phone',
        'Vehicle Reg',
        'Subtotal',
        'Discount',
        'GST Total',
        'Core Charge',
        'Grand Total',
        'Payment Method',
        'Status',
      ],
      ...invoices.map((i) => [
            i.number,
            Fmt.date(i.createdAt),
            i.customerName,
            i.customerPhone ?? '',
            i.vehicleReg ?? '',
            i.subtotal,
            i.discountAmount,
            i.gstTotal,
            i.coreTotal,
            i.grandTotal,
            i.paymentMethod.label,
            i.isCancelled ? 'Cancelled' : 'Paid',
          ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pitstock_sales_report.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)],
        text: 'PitStock sales report CSV');
  }

  /// Export Stock Movements audit trail to CSV.
  static Future<void> exportMovementsCsv(
      BuildContext context, List<StockMovement> movements) async {
    final rows = <List<dynamic>>[
      ['Movement ID', 'Part ID', 'Type', 'Delta (Qty)', 'Reference', 'Date'],
      ...movements.map((m) => [
            m.id,
            m.partId,
            m.type.label,
            m.delta,
            m.reference ?? '',
            Fmt.date(m.date),
          ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pitstock_movements_log.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)],
        text: 'PitStock stock movements log');
  }

  /// Export comprehensive printable PDF summary report.
  static Future<void> exportPdf(
      BuildContext context, List<Part> parts, String shopName) async {
    final doc = pw.Document();
    final totalValue = parts.fold(0.0, (s, p) => s + p.stockValue);
    final totalUnits = parts.fold(0, (s, p) => s + p.quantity);
    final lowStockCount = parts.where((p) => p.isLowStock).length;
    final outOfStockCount = parts.where((p) => p.isOutOfStock).length;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('$shopName — Inventory Valuation Report',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Generated: ${Fmt.date(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              )),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total SKUs: ${parts.length}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('Total Stock Units: $totalUnits',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('Low Stock: $lowStockCount',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.orange900)),
                pw.Text('Out of Stock: $outOfStockCount',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.red900)),
                pw.Text('Stock Valuation: Rs ${totalValue.toStringAsFixed(0)}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Part Name', 'Part No', 'Brand', 'Category', 'Loc', 'Qty', 'Cost (₹)', 'Sell (₹)', 'Value (₹)'],
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            headerStyle: pw.TextStyle(
                fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            data: parts
                .map((p) => [
                      p.name,
                      p.partNumber,
                      p.brand,
                      p.category,
                      p.binLocation,
                      '${p.quantity} ${p.unit}',
                      p.costPrice.toStringAsFixed(0),
                      p.sellingPrice.toStringAsFixed(0),
                      p.stockValue.toStringAsFixed(0),
                    ])
                .toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (f) => doc.save(),
      name: 'PitStock_Inventory_Report.pdf',
    );
  }
}
