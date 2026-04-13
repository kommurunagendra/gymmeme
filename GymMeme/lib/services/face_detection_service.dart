import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionResult {
  final bool hasFaces;
  final int faceCount;

  const FaceDetectionResult({
    required this.hasFaces,
    required this.faceCount,
  });
}

class FaceDetectionService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: false,
      enableLandmarks: false,
      enableContours: false,
      enableTracking: false,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  /// Detects faces in the given image file.
  /// Returns a result indicating whether faces were found.
  Future<FaceDetectionResult> detectFaces(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final faces = await _detector.processImage(inputImage);
    return FaceDetectionResult(
      hasFaces: faces.isNotEmpty,
      faceCount: faces.length,
    );
  }

  void dispose() => _detector.close();
}
