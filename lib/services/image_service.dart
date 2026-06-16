import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';

/// Fotoğraf seçim sonucu (çağırana net geri bildirim için).
enum ImagePickStatus { success, cancelled, tooLarge, failed }

class ImagePickResult {
  final ImagePickStatus status;
  final String? base64;
  const ImagePickResult(this.status, [this.base64]);

  bool get ok => status == ImagePickStatus.success && base64 != null;
}

/// Fotoğrafı seçer, Firestore'a sığacak şekilde sıkıştırır ve base64 döndürür.
/// Firebase Storage KULLANMAZ (ücretsiz kalmak için).
class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Galeri veya kameradan fotoğraf seçip sıkıştırılmış base64 döndürür.
  /// Hedef: uzun kenar 800px, JPEG q70, ~250KB altı.
  /// Sonuç tipi sayesinde çağıran "iptal / çok büyük / hata" durumlarını ayırır.
  Future<ImagePickResult> pick({bool fromCamera = false}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: AppConfig.imageMaxDimension.toDouble(),
        maxHeight: AppConfig.imageMaxDimension.toDouble(),
        imageQuality: AppConfig.imageQuality,
      );
      if (picked == null) {
        return const ImagePickResult(ImagePickStatus.cancelled);
      }

      // image_picker zaten maxWidth/quality ile küçültür. Ek sıkıştırma denenir;
      // bazı cihaz formatlarında (ör. HEIC) sıkıştırma null dönebilir — bu durumda
      // picker'ın çıktısı kullanılır.
      Uint8List? bytes = await _compress(File(picked.path));
      bytes ??= await picked.readAsBytes();

      // GÜVENLİK: Sıkıştırma başarısız olup ham (büyük) görsel geldiyse, base64
      // Firestore 1MB döküman limitini aşabilir. Sınırı aşan görseli reddet.
      if (bytes.lengthInBytes > AppConfig.maxImageBytes) {
        return const ImagePickResult(ImagePickStatus.tooLarge);
      }
      return ImagePickResult(ImagePickStatus.success, base64Encode(bytes));
    } catch (_) {
      // Kamera/galeri izni reddi veya beklenmedik hata.
      return const ImagePickResult(ImagePickStatus.failed);
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
