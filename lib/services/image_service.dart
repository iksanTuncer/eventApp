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
    try {
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: AppConfig.imageMaxDimension.toDouble(),
        maxHeight: AppConfig.imageMaxDimension.toDouble(),
        imageQuality: AppConfig.imageQuality,
      );
      if (picked == null) return null;

      // image_picker zaten maxWidth/quality ile küçültür. Ek sıkıştırma denenir;
      // bazı cihaz formatlarında (ör. HEIC) sıkıştırma null dönebilir — bu durumda
      // picker'ın çıktısı doğrudan kullanılır (görselin "seçilememe" sorununu önler).
      Uint8List? bytes = await _compress(File(picked.path));
      bytes ??= await picked.readAsBytes();
      return base64Encode(bytes);
    } catch (_) {
      // Kamera/galeri izni reddi veya beklenmedik hata: sessizce null dön.
      return null;
    }
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
