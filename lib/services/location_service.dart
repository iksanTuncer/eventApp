import 'package:geolocator/geolocator.dart';

/// Cihaz GPS konumu. Ücretsiz (Google Maps SDK ücretsiz kotada).
class LocationService {
  /// İzin ister ve mevcut konumu döndürür. İzin yoksa null.
  static Future<Position?> getCurrent() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return null;
    }
    if (perm == LocationPermission.deniedForever) return null;

    return Geolocator.getCurrentPosition();
  }
}
