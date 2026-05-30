import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// Converts a [CameraImage] from a live stream into an [InputImage] that
/// Google ML Kit can process. Handles Android (NV21/YUV) and iOS (BGRA).
class MlkitInput {
  static ImageFormatGroup get imageFormatGroup =>
      Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888;

  static final _rotations = <int, InputImageRotation>{
    0: InputImageRotation.rotation0deg,
    90: InputImageRotation.rotation90deg,
    180: InputImageRotation.rotation180deg,
    270: InputImageRotation.rotation270deg,
  };

  static InputImage? fromCameraImage(
      CameraImage image, CameraDescription camera) {
    final rotation =
        _rotations[camera.sensorOrientation] ?? InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // For NV21 (Android) and BGRA (iOS) we can use the first plane buffer.
    final plane = image.planes.first;
    final bytes = _concatPlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  static Uint8List _concatPlanes(List<Plane> planes) {
    final builder = BytesBuilder();
    for (final p in planes) {
      builder.add(p.bytes);
    }
    return builder.toBytes();
  }
}
