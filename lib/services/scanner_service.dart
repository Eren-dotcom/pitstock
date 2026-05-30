import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

/// Live camera scanning powered by free, on-device Google ML Kit.
///
///  • Barcode scanning  → instantly match a part by its barcode.
///  • Object detection  → "live scan" of shop/garage shelves; detects and
///    classifies objects in frame so the user can rapidly log items.
///
/// Both run fully OFFLINE with no API key and no cost.
class ScannerService {
  final BarcodeScanner _barcode = BarcodeScanner();

  late final ObjectDetector _objectDetector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.stream, // live continuous detection
      classifyObjects: true,
      multipleObjects: true,
    ),
  );

  Future<List<Barcode>> scanBarcodes(InputImage image) =>
      _barcode.processImage(image);

  Future<List<DetectedObject>> detectObjects(InputImage image) =>
      _objectDetector.processImage(image);

  void dispose() {
    _barcode.close();
    _objectDetector.close();
  }
}
