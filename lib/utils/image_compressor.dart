import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  /// Compresses the given image to WebP format.
  /// If compression fails, it returns the original file.
  static Future<File> compressToWebp(String imagePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.webp';
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        format: CompressFormat.webp,
        quality: 80,
        minWidth: 800,
        minHeight: 800,
      );
      
      return compressedFile != null ? File(compressedFile.path) : File(imagePath);
    } catch (e) {
      return File(imagePath);
    }
  }
}
