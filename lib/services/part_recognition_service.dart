import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// One recognition guess.
class RecognitionResult {
  final String label; // raw model/labeler label
  final double confidence; // 0..1
  final String? mappedCategory; // PitStock category if we could map it
  RecognitionResult({
    required this.label,
    required this.confidence,
    this.mappedCategory,
  });
}

/// Photo-based part recognition.
///
/// Two engines, tried in order — both 100% on-device & offline:
///   1. CUSTOM TFLITE  — if you drop a trained model at
///      assets/models/parts_model.tflite (+ parts_labels.txt), it is used.
///      This is the "trained to identify spare parts" path.
///   2. ML KIT FALLBACK — Google's free generic image labeller. Works with
///      zero training so the feature is usable immediately, mapping generic
///      labels (e.g. "tire", "wheel", "machine") to PitStock categories.
///
/// Either way the top guess(es) are mapped to your catalogue categories and
/// can launch a pre-filtered search.
class PartRecognitionService {
  static const _modelPath = 'assets/models/parts_model.tflite';
  static const _labelsPath = 'assets/models/parts_labels.txt';
  static const _inputSize = 224; // standard for MobileNet-style models

  Interpreter? _interpreter;
  List<String>? _labels;
  bool _triedLoadModel = false;
  bool get hasCustomModel => _interpreter != null && _labels != null;

  ImageLabeler? _labeler;

  /// Maps generic / model labels to PitStock categories.
  static const Map<String, String> _categoryMap = {
    // tyres
    'tire': 'Tyres', 'tyre': 'Tyres', 'wheel': 'Tyres', 'rim': 'Tyres',
    // battery
    'battery': 'Battery',
    // lighting
    'light': 'Lighting', 'bulb': 'Lighting', 'headlight': 'Lighting',
    'lamp': 'Lighting',
    // filters
    'filter': 'Filters', 'air filter': 'Filters', 'oil filter': 'Filters',
    // brakes
    'brake': 'Brakes', 'disc': 'Brakes', 'rotor': 'Brakes', 'pad': 'Brakes',
    // fluids
    'oil': 'Lubricants & Fluids', 'bottle': 'Lubricants & Fluids',
    'coolant': 'Cooling', 'radiator': 'Cooling',
    // ignition
    'spark plug': 'Ignition', 'plug': 'Ignition',
    // belts / bearings
    'belt': 'Belts & Hoses', 'hose': 'Belts & Hoses',
    'bearing': 'Bearings', 'gear': 'Clutch & Transmission',
    // wipers / mirrors / body
    'wiper': 'Wipers', 'mirror': 'Body & Exterior', 'bumper': 'Body & Exterior',
    // generic machine-ish labels → engine bucket
    'machine': 'Engine', 'engine': 'Engine', 'motor': 'Electrical',
    'auto part': 'Engine', 'metal': 'Engine', 'tool': 'Engine',
  };

  Future<void> _ensureLoaded() async {
    if (_triedLoadModel) return;
    _triedLoadModel = true;
    try {
      // Will throw if the asset isn't bundled — that's fine, we fall back.
      await rootBundle.load(_modelPath);
      _interpreter = await Interpreter.fromAsset(_modelPath);
      final raw = await rootBundle.loadString(_labelsPath);
      _labels = raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      _interpreter = null;
      _labels = null;
    }
  }

  /// Recognise the part in [imagePath]. Returns ranked guesses.
  Future<List<RecognitionResult>> recognise(String imagePath) async {
    await _ensureLoaded();
    if (hasCustomModel) {
      return _recogniseTflite(imagePath);
    }
    return _recogniseMlKit(imagePath);
  }

  // ---------- Custom TFLite engine ----------
  Future<List<RecognitionResult>> _recogniseTflite(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return [];
    final resized =
        img.copyResize(decoded, width: _inputSize, height: _inputSize);

    // Build a [1,224,224,3] float input normalised to 0..1.
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final px = resized.getPixel(x, y);
          return [px.r / 255.0, px.g / 255.0, px.b / 255.0];
        }),
      ),
    );

    final labels = _labels!;
    final output =
        List.filled(labels.length, 0.0).reshape([1, labels.length]);
    _interpreter!.run(input, output);

    final scores = List<double>.from((output[0] as List).map((e) => (e as num).toDouble()));
    final ranked = <RecognitionResult>[];
    for (var i = 0; i < labels.length && i < scores.length; i++) {
      ranked.add(RecognitionResult(
        label: labels[i],
        confidence: scores[i],
        mappedCategory: _mapCategory(labels[i]),
      ));
    }
    ranked.sort((a, b) => b.confidence.compareTo(a.confidence));
    return ranked.take(5).toList();
  }

  // ---------- ML Kit fallback engine ----------
  Future<List<RecognitionResult>> _recogniseMlKit(String imagePath) async {
    _labeler ??= ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.4));
    final input = InputImage.fromFilePath(imagePath);
    final labels = await _labeler!.processImage(input);
    final results = labels
        .map((l) => RecognitionResult(
              label: l.label,
              confidence: l.confidence,
              mappedCategory: _mapCategory(l.label),
            ))
        .toList();
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results.take(5).toList();
  }

  String? _mapCategory(String label) {
    final l = label.toLowerCase();
    // exact catalogue category name?
    for (final entry in _categoryMap.entries) {
      if (l.contains(entry.key)) return entry.value;
    }
    return null;
  }

  void dispose() {
    _interpreter?.close();
    _labeler?.close();
  }
}
