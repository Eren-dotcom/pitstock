import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../models/scanned_item.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../data/database_helper.dart';
import '../services/ocr_service.dart';
import '../theme/app_theme.dart';
import 'scan_review_screen.dart';

/// AI Bill / Invoice scanner.
/// Pick a photo of a supplier bill → on-device OCR → parse line items →
/// review & commit to inventory. 100% free & offline (Google ML Kit).
class BillScanScreen extends StatefulWidget {
  const BillScanScreen({super.key});
  @override
  State<BillScanScreen> createState() => _BillScanScreenState();
}

class _BillScanScreenState extends State<BillScanScreen> {
  final _ocr = OcrService();
  final _picker = ImagePicker();
  File? _image;
  bool _busy = false;
  String _status = '';

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final x = await _picker.pickImage(source: source, imageQuality: 90);
    if (x == null) return;

    // PRIVACY — On-device cropping: let the user restrict the scan area
    // strictly to the parts-list section, excluding headers/footers.
    final cropped = await ImageCropper().cropImage(
      sourcePath: x.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop to parts list only',
          toolbarColor: AppTheme.primary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop to parts list only'),
      ],
    );
    final path = cropped?.path ?? x.path;

    setState(() {
      _image = File(path);
      _busy = true;
      _status = 'Reading text with on-device AI…';
    });

    try {
      // RBAC — only Owner/Manager may retain the original invoice image.
      final auth = context.read<AuthProvider>();
      if (auth.role.canViewInvoiceImages) {
        await DatabaseHelper.instance
            .saveInvoiceImage(const Uuid().v4(), path, 'bill-scan');
      }

      final items = await _ocr.parseBill(path);
      setState(() => _status = 'Matching ${items.length} items to catalogue…');
      final inv = context.read<InventoryProvider>();
      inv.autoMatch(items);

      if (!mounted) return;
      setState(() => _busy = false);

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No line items detected. Try a clearer, well-lit photo.')));
        return;
      }
      _openReview(items);
    } catch (e) {
      setState(() {
        _busy = false;
        _status = 'Error: $e';
      });
    }
  }

  void _openReview(List<ScannedItem> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanReviewScreen(
          items: items,
          source: MovementSource.bill,
          title: 'Review Bill Items',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Bill Scanner')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.receipt_long, color: Colors.white, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Scan a supplier bill',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text(
                        'AI reads items, quantity & price, then adds them to stock.',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(.4)),
              ),
              child: _image == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined,
                              size: 64,
                              color: Theme.of(context)
                                  .disabledColor
                                  .withOpacity(.5)),
                          const SizedBox(height: 8),
                          const Text('No bill selected'),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            Row(children: [
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Expanded(child: Text(_status)),
            ]).animate().fadeIn(),
          ],
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                onPressed: _busy ? null : () => _pick(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(.1),
                borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(children: [
                  Icon(Icons.privacy_tip, color: AppTheme.secondary, size: 18),
                  SizedBox(width: 6),
                  Text('Privacy protections',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ]),
                SizedBox(height: 6),
                Text('• Crop to the parts list only (financial data excluded)\n'
                    '• AI parses just the line-item table, ignoring headers/footers\n'
                    '• You preview & select items before anything is saved\n'
                    '• Original invoice image is visible to Owner/Manager only',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: flatten the bill, avoid shadows and capture straight-on for best accuracy.',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.6)),
          ),
        ],
      ),
    );
  }
}
