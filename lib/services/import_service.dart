import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../models/part.dart';
import '../models/scanned_item.dart';

/// Bulk import parts from CSV or Excel (.xlsx) supplier price lists.
///
/// Expected columns (header row, case-insensitive, flexible order):
///   name | partNumber | brand | category | qty | cost | selling | gst | barcode | shelf | bin
class ImportService {
  static Future<List<ScannedItem>> fromFile(String path) async {
    final lower = path.toLowerCase();
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
      return _fromExcel(path);
    }
    return _fromCsv(path);
  }

  static Future<List<ScannedItem>> _fromCsv(String path) async {
    final raw = await File(path).readAsString();
    final rows = const CsvToListConverter(eol: '\n').convert(raw);
    if (rows.isEmpty) return [];
    final header = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final items = <ScannedItem>[];
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      final item = _rowToItem(header, r.map((e) => e?.toString() ?? '').toList());
      if (item != null) items.add(item);
    }
    return items;
  }

  static Future<List<ScannedItem>> _fromExcel(String path) async {
    final bytes = await File(path).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final items = <ScannedItem>[];
    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table]!;
      if (sheet.rows.isEmpty) continue;
      final header = sheet.rows.first
          .map((c) => (c?.value?.toString() ?? '').toLowerCase().trim())
          .toList();
      for (var i = 1; i < sheet.rows.length; i++) {
        final r = sheet.rows[i]
            .map((c) => c?.value?.toString() ?? '')
            .toList();
        final item = _rowToItem(header, r);
        if (item != null) items.add(item);
      }
      break; // first sheet only
    }
    return items;
  }

  static int _col(List<String> header, List<String> names) {
    for (final n in names) {
      final i = header.indexWhere((h) => h == n);
      if (i >= 0) return i;
    }
    return -1;
  }

  static String _get(List<String> row, int i) =>
      (i >= 0 && i < row.length) ? row[i].trim() : '';

  static ScannedItem? _rowToItem(List<String> header, List<String> row) {
    final ni = _col(header, ['name', 'part name', 'description', 'item']);
    final name = _get(row, ni);
    if (name.isEmpty) return null;
    final pn = _get(row, _col(header, ['partnumber', 'part number', 'part no', 'sku']));
    final qty = int.tryParse(
            _get(row, _col(header, ['qty', 'quantity', 'stock']))) ??
        0;
    final price = double.tryParse(_get(
            row, _col(header, ['selling', 'mrp', 'price', 'rate']))
        .replaceAll(',', '')) ??
        0;
    final gst =
        double.tryParse(_get(row, _col(header, ['gst', 'gst%', 'tax']))) ?? 18;
    return ScannedItem(
      name: name,
      partNumber: pn.isEmpty ? null : pn,
      quantity: qty == 0 ? 1 : qty,
      price: price,
      gstPercent: gst,
      confidence: 1.0,
    );
  }
}
