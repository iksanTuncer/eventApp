import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';

/// Fotoğrafı seçer, Firestore'a sığacak şekilde sıkıştırır ve base64 döndürür.
/// Firebase Storage KULLANMAZ (ücretsiz kalmak için).
class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Galeri veya kameradan fotoğraf seçip sıkıştırılmış base64 döndürür.
  /// Hedef: uzun kenar 800px, JPEG q70, ~250KB altı.
  Future<String?> pickAndEncode({bool fromCamera = false}) async {
    final XFile? picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: AppConfig.imageMaxDimension.toDouble(),
      maxHeight: AppConfig.imageMaxDimension.toDouble(),
      imageQuality: AppConfig.imageQuality,
    );
    if (picked == null) return null;

    final bytes = await _compress(File(picked.path));
    if (bytes == null) return null;
    return base64Encode(bytes);
  }

  Future<Uint8List?> _compress(File file) async {
    var result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: AppConfig.imageMaxDimension,
      minHeight: AppConfig.imageMaxDimension,
      quality: AppConfig.imageQuality,
      format: CompressFormat.jpeg,
    );

    // Hâlâ büyükse kaliteyi düşürerek tekrar dene
    int quality = AppConfig.imageQuality;
    while (result != null &&
        result.lengthInBytes > AppConfig.maxImageBytes &&
        quality > 30) {
      quality -= 15;
      result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: AppConfig.imageMaxDimension,
        minHeight: AppConfig.imageMaxDimension,
        quality: quality,
        format: CompressFormat.jpeg,
      );
    }
    return result;
  }

  /// base64 stringi tekrar byte'a çevirir (Image.memory için).
  static Uint8List decode(String b64) => base64Decode(b64);
}
