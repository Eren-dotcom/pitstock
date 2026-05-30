import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/part.dart';
import '../providers/inventory_provider.dart';
import '../services/part_recognition_service.dart';
import '../services/search_service.dart';
import '../theme/app_theme.dart';
import '../widgets/part_tile.dart';
import 'part_detail_screen.dart';
import 'part_edit_screen.dart';

/// Point the camera (or pick a photo) at a spare part → on-device AI guesses
/// what it is → matches to your catalogue → search or add.
class PhotoRecognitionScreen extends StatefulWidget {
  const PhotoRecognitionScreen({super.key});
  @override
  State<PhotoRecognitionScreen> createState() => _PhotoRecognitionScreenState();
}

class _PhotoRecognitionScreenState extends State<PhotoRecognitionScreen> {
  final _recogniser = PartRecognitionService();
  final _picker = ImagePicker();
  File? _image;
  bool _busy = false;
  List<RecognitionResult> _results = [];
  List<Part> _matches = [];
  String _engine = '';

  @override
  void dispose() {
    _recogniser.dispose();
    super.dispose();
  }

  Future<void> _capture(ImageSource source) async {
    final x = await _picker.pickImage(source: source, imageQuality: 90);
    if (x == null) return;
    setState(() {
      _image = File(x.path);
      _busy = true;
      _results = [];
      _matches = [];
    });
    try {
      final res = await _recogniser.recognise(x.path);
      final inv = context.read<InventoryProvider>();
      final matches = _findMatches(inv, res);
      if (!mounted) return;
      setState(() {
        _results = res;
        _matches = matches;
        _engine = _recogniser.hasCustomModel
            ? 'Custom TFLite model'
            : 'ML Kit (generic)';
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _busy = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Recognition failed: $e')));
      }
    }
  }

  List<Part> _findMatches(InventoryProvider inv, List<RecognitionResult> res) {
    final seen = <String>{};
    final out = <Part>[];
    for (final r in res) {
      // 1) try the mapped category
      if (r.mappedCategory != null) {
        final f = SearchFilters(categories: {r.mappedCategory!});
        for (final p in inv.search(f)) {
          if (seen.add(p.id)) out.add(p);
        }
      }
      // 2) also fuzzy-match the raw label text against names
      final f2 = SearchFilters(query: r.label);
      for (final p in inv.search(f2)) {
        if (seen.add(p.id)) out.add(p);
      }
      if (out.length >= 15) break;
    }
    return out.take(15).toList();
  }

  String? get _topCategory {
    for (final r in _results) {
      if (r.mappedCategory != null) return r.mappedCategory;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identify Part by Photo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: AppTheme.sunsetGradient,
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: const [
              Icon(Icons.center_focus_strong, color: Colors.white, size: 36),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Snap a part to identify it',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('On-device AI suggests the category & matching stock.',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 4 / 3,
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
                          Icon(Icons.photo_camera_back,
                              size: 64,
                              color: Theme.of(context)
                                  .disabledColor
                                  .withOpacity(.5)),
                          const SizedBox(height: 8),
                          const Text('No photo yet'),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                onPressed: _busy ? null : () => _capture(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                onPressed: _busy ? null : () => _capture(ImageSource.gallery),
              ),
            ),
          ]),
          if (_busy) ...[
            const SizedBox(height: 20),
            Row(children: const [
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Analysing image on-device…'),
            ]).animate().fadeIn(),
          ],
          if (_results.isNotEmpty) ..._buildResults(),
        ],
      ),
    );
  }

  List<Widget> _buildResults() {
    final top = _results.first;
    return [
      const SizedBox(height: 20),
      Row(children: [
        Text('AI guesses',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        Chip(
          label: Text(_engine, style: const TextStyle(fontSize: 10)),
          visualDensity: VisualDensity.compact,
          backgroundColor: AppTheme.secondary.withOpacity(.15),
          side: BorderSide.none,
        ),
      ]),
      const SizedBox(height: 8),
      ..._results.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${r.label}${r.mappedCategory != null ? '  →  ${r.mappedCategory}' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: r.confidence.clamp(0, 1),
                          minHeight: 8,
                          backgroundColor: AppTheme.primary.withOpacity(.12),
                          valueColor:
                              const AlwaysStoppedAnimation(AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('${(r.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          )),
      const SizedBox(height: 12),
      Row(children: [
        if (_topCategory != null)
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.search),
              label: Text('Search ${_topCategory!}'),
              onPressed: () => Navigator.pop(context, _topCategory),
            ),
          ),
        if (_topCategory != null) const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add as new'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PartEditScreen(
                  prefillName: top.label,
                ),
              ),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 20),
      if (_matches.isNotEmpty) ...[
        Text('Matching stock (${_matches.length})',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ..._matches.map((p) => PartTile(
              part: p,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PartDetailScreen(partId: p.id))),
            )),
      ] else
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(.12),
              borderRadius: BorderRadius.circular(14)),
          child: const Text(
              'No matching parts in your inventory for this guess. '
              'You can add it as a new part.'),
        ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(.08),
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: const [
          Icon(Icons.tips_and_updates, size: 18, color: AppTheme.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
                'Tip: drop a trained parts_model.tflite into assets/models/ '
                'for far more accurate, part-specific recognition.',
                style: TextStyle(fontSize: 11.5)),
          ),
        ]),
      ),
    ];
  }
}
