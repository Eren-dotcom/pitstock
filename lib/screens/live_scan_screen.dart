import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
import '../services/scanner_service.dart';
import '../theme/app_theme.dart';
import '../utils/mlkit_input.dart';
import 'part_detail_screen.dart';
import 'part_edit_screen.dart';

/// Live camera scanning of shop / garage items.
/// Continuously detects objects and barcodes in the frame using free,
/// on-device Google ML Kit, then lets the user log matches into inventory.
class LiveScanScreen extends StatefulWidget {
  const LiveScanScreen({super.key});
  @override
  State<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen> {
  CameraController? _camera;
  final _scanner = ScannerService();
  bool _initing = true;
  bool _processing = false;
  bool _barcodeMode = true;

  String? _lastBarcode;
  List<String> _detectedLabels = [];
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: MlkitInput.imageFormatGroup,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _camera = controller;
        _initing = false;
      });
      await controller.startImageStream(_onFrame);
    } catch (e) {
      setState(() {
        _cameraError = '$e';
        _initing = false;
      });
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_processing || _camera == null) return;
    _processing = true;
    try {
      final input = MlkitInput.fromCameraImage(image, _camera!.description);
      if (input == null) {
        _processing = false;
        return;
      }
      if (_barcodeMode) {
        final codes = await _scanner.scanBarcodes(input);
        if (codes.isNotEmpty) {
          final code = codes.first.rawValue;
          if (code != null && code != _lastBarcode) {
            _lastBarcode = code;
            _onBarcode(code);
          }
        }
      } else {
        final objects = await _scanner.detectObjects(input);
        final labels = <String>[];
        for (final o in objects) {
          for (final l in o.labels) {
            labels.add('${l.text} (${(l.confidence * 100).toStringAsFixed(0)}%)');
          }
        }
        if (mounted) setState(() => _detectedLabels = labels);
      }
    } catch (_) {
      // swallow per-frame errors
    } finally {
      _processing = false;
    }
  }

  void _onBarcode(String code) {
    final inv = context.read<InventoryProvider>();
    final part = inv.byBarcode(code);
    _camera?.stopImageStream();
    if (part != null) {
      Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PartDetailScreen(partId: part.id)))
          .then((_) => _camera?.startImageStream(_onFrame));
    } else {
      showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_2, size: 48, color: AppTheme.primary),
              const SizedBox(height: 8),
              Text('New barcode: $code'),
              const SizedBox(height: 4),
              const Text('No matching part. Create one?'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PartEditScreen(prefillBarcode: code)))
                      .then((_) => _camera?.startImageStream(_onFrame));
                },
                child: const Text('Add new part'),
              ),
            ],
          ),
        ),
      ).whenComplete(() {
        _lastBarcode = null;
        _camera?.startImageStream(_onFrame);
      });
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Live Scan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: SegmentedButton<bool>(
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: true, label: Text('Barcode')),
                  ButtonSegment(value: false, label: Text('Object')),
                ],
                selected: {_barcodeMode},
                onSelectionChanged: (s) =>
                    setState(() => _barcodeMode = s.first),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initing) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (_cameraError != null || _camera == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography,
                  color: Colors.white54, size: 64),
              const SizedBox(height: 12),
              const Text('Camera unavailable',
                  style: TextStyle(color: Colors.white)),
              const SizedBox(height: 6),
              Text(_cameraError ?? 'Grant camera permission and retry.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_camera!),
        // scan frame overlay
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.secondary, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _barcodeMode
                      ? 'Point at a part barcode'
                      : 'Detecting objects in view',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                if (!_barcodeMode && _detectedLabels.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _detectedLabels
                        .take(6)
                        .map((l) => Chip(
                            label: Text(l,
                                style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppTheme.secondary))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
