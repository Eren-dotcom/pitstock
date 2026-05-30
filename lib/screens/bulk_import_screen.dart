import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../models/scanned_item.dart';
import '../providers/inventory_provider.dart';
import '../services/import_service.dart';
import '../theme/app_theme.dart';
import 'scan_review_screen.dart';

/// Bulk import parts from a CSV or Excel supplier price list.
class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});
  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  bool _busy = false;
  String _status = '';

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _busy = true;
      _status = 'Parsing file…';
    });
    try {
      final items = await ImportService.fromFile(result.files.single.path!);
      final inv = context.read<InventoryProvider>();
      inv.autoMatch(items);
      if (!mounted) return;
      setState(() => _busy = false);
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No rows found. Check column headers.')));
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanReviewScreen(
            items: items,
            source: MovementSource.scan,
            title: 'Review Imported Items',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _busy = false;
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Import (CSV / Excel)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: const [
              Icon(Icons.upload_file, color: Colors.white, size: 36),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                    'Import many parts at once from a supplier price list.',
                    style: TextStyle(color: Colors.white)),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Expected columns (header row):',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                  'name | partNumber | brand | category | qty | cost | selling | gst | barcode | shelf | bin',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ),
          const SizedBox(height: 8),
          Text('Column order is flexible; matching is case-insensitive.',
              style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
          const SizedBox(height: 24),
          if (_busy)
            Row(children: [
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Text(_status),
            ])
          else
            FilledButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose CSV / Excel file'),
              onPressed: _pick,
            ),
        ],
      ),
    );
  }
}
