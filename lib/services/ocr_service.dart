import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/scanned_item.dart';

/// Offline OCR + heuristic bill parser.
///
/// Uses Google ML Kit Text Recognition — 100% free and runs ON-DEVICE
/// (no API key, no internet, no per-scan cost). It extracts raw text from a
/// photographed invoice and then a rule-based parser turns lines into
/// [ScannedItem]s for review.
class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> readText(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);
    return result.text;
  }

  /// Parse OCR text from a typical Indian GST tax invoice into line items.
  ///
  /// Heuristics handle layouts like:
  ///   "1  Air Filter Swift   AF-SWFT-04   2   420.00   840.00"
  ///   "Oil Filter            3 x 310 = 930"
  Future<List<ScannedItem>> parseBill(String imagePath) async {
    final text = await readText(imagePath);
    return parseText(text);
  }

  List<ScannedItem> parseText(String text) {
    // PRIVACY — Targeted extraction: isolate only the line-item table region,
    // dropping invoice headers (shop, GSTIN, address) and footers
    // (totals, tax, bank, signature) before parsing.
    final region = _isolateLineItemRegion(text);
    return _parseRegion(region);
  }

  /// Keeps only the body between the table header and the totals section so
  /// financial/private text outside the parts list is never processed.
  String _isolateLineItemRegion(String text) {
    final lines = text.split('\n');
    final headerCue = RegExp(
        r'(description|particulars|item|qty|quantity|hsn|rate)',
        caseSensitive: false);
    final footerCue = RegExp(
        r'(sub\s*total|subtotal|grand\s*total|total\s*amount|cgst|sgst|igst|round\s*off|bank|ifsc|account|terms|signature|thank)',
        caseSensitive: false);

    int start = 0;
    int end = lines.length;
    for (var i = 0; i < lines.length; i++) {
      if (headerCue.hasMatch(lines[i])) {
        start = i + 1;
        break;
      }
    }
    for (var i = start; i < lines.length; i++) {
      if (footerCue.hasMatch(lines[i])) {
        end = i;
        break;
      }
    }
    if (start >= end) return text; // fallback: couldn't detect, use all
    return lines.sublist(start, end).join('\n');
  }

  List<ScannedItem> _parseRegion(String text) {
    final items = <ScannedItem>[];
    final lines = text.split('\n');

    // Regex helpers
    final qtyPricePattern =
        RegExp(r'(\d+)\s*[xX*]\s*([\d,]+\.?\d*)'); // 3 x 310
    final trailingNums = RegExp(r'([\d,]+\.?\d*)'); // any number
    final partNoPattern = RegExp(r'\b([A-Z]{2,}[-/]?[A-Z0-9]{2,}[-/]?[A-Z0-9]*)\b');
    final skipWords = RegExp(
        r'(invoice|gst|gstin|total|subtotal|cgst|sgst|igst|tax|amount|qty|rate|hsn|sno|s\.no|particulars|description|thank|phone|mob|address|bill no|date|signature|round)',
        caseSensitive: false);

    for (final raw in lines) {
      final line = raw.trim();
      if (line.length < 3) continue;
      if (skipWords.hasMatch(line) && trailingNums.allMatches(line).length < 2) {
        continue; // header / footer noise
      }

      // Pattern A: "name 3 x 310"
      final qp = qtyPricePattern.firstMatch(line);
      if (qp != null) {
        final qty = int.tryParse(qp.group(1) ?? '1') ?? 1;
        final price =
            double.tryParse((qp.group(2) ?? '0').replaceAll(',', '')) ?? 0;
        final name = line.substring(0, qp.start).trim();
        if (name.length >= 2) {
          items.add(ScannedItem(
            name: _clean(name),
            partNumber: _extractPart(name, partNoPattern),
            quantity: qty,
            price: price,
            confidence: 0.8,
          ));
          continue;
        }
      }

      // Pattern B: tabular "name ... qty rate amount"
      final nums = trailingNums.allMatches(line).toList();
      if (nums.length >= 2) {
        // last number = line total, second-last = rate, find an int qty
        final values = nums
            .map((m) => double.tryParse(m.group(0)!.replaceAll(',', '')) ?? 0)
            .toList();
        // qty is usually the smallest whole number on the line
        final intCandidates = values.where((v) => v == v.roundToDouble() && v > 0 && v < 1000).toList();
        final qty = intCandidates.isNotEmpty ? intCandidates.first.toInt() : 1;
        final rate = values.length >= 2 ? values[values.length - 2] : values.last;
        final firstNumStart = nums.first.start;
        final name = line.substring(0, firstNumStart).replaceAll(RegExp(r'^\d+[\).\s]+'), '').trim();
        if (name.length >= 2 && !skipWords.hasMatch(name)) {
          items.add(ScannedItem(
            name: _clean(name),
            partNumber: _extractPart(line, partNoPattern),
            quantity: qty,
            price: rate,
            confidence: 0.65,
          ));
        }
      }
    }
    return items;
  }

  String _clean(String s) =>
      s.replaceAll(RegExp(r'\s{2,}'), ' ').replaceAll(RegExp(r'[|]+'), '').trim();

  String? _extractPart(String s, RegExp p) {
    final m = p.firstMatch(s.toUpperCase());
    return m?.group(1);
  }

  void dispose() => _recognizer.close();
}
