import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../core/constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Compress image to max 1MB then upload to Firebase Storage
  /// Returns the download URL
  Future<String> uploadMemeImage({
    required String localPath,
    required String memeId,
    required String userId,
  }) async {
    final compressed = await _compressImage(localPath, memeId);
    final ref = _storage
        .ref()
        .child(AppConstants.memesStoragePath)
        .child(userId)
        .child('$memeId.jpg');

    await ref.putFile(
      File(compressed),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return ref.getDownloadURL();
  }

  Future<String> _compressImage(String inputPath, String name) async {
    final dir = await getTemporaryDirectory();
    final outputPath = p.join(dir.path, '${name}_compressed.jpg');

    final result = await FlutterImageCompress.compressAndGetFile(
      inputPath,
      outputPath,
      quality: 80,
      minWidth: 1080,
      minHeight: 1080,
    );

    return result?.path ?? inputPath;
  }

  Future<void> deleteMemeImage(String userId, String memeId) async {
    try {
      await _storage
          .ref()
          .child(AppConstants.memesStoragePath)
          .child(userId)
          .child('$memeId.jpg')
          .delete();
    } catch (_) {
      // Ignore — file may not exist
    }
  }
}
