import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Etkileşimsiz küçük harita önizlemesi (OpenStreetMap, ücretsiz).
/// Verilen konuma bir pin koyar. Form önizlemesi ve etkinlik detayında kullanılır.
///
/// [onTap] verilirse harita üzerine dokunmak bu geri-çağrımı tetikler
/// (ör. cihazın harita uygulamasında açmak için). Harita kendisi etkileşimsizdir,
/// bu yüzden dokunuş güvenle yakalanır.
class StaticMap extends StatelessWidget {
  final double lat;
  final double lng;
  final double height;
  final VoidCallback? onTap;
  const StaticMap({
    super.key,
    required this.lat,
    required this.lng,
    this.height = 160,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = LatLng(lat, lng);
    final map = FlutterMap(
      options: MapOptions(
        initialCenter: p,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.eventapp.event_app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: p,
              width: 44,
              height: 44,
              alignment: Alignment.bottomCenter,
              child: const Icon(Icons.location_pin,
                  size: 44, color: Color(0xFFC8853A)),
            ),
          ],
        ),
      ],
    );

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Harita arka planı (kareler yüklenene kadar boş kalmasın diye).
          Container(color: const Color(0xFFE8EFE6)),
          // Haritanın kendisi dokunuşu yutmasın: IgnorePointer ile sar.
          IgnorePointer(child: map),
          if (onTap != null) ...[
            // Tüm alanı kaplayan dokunma hedefi → maps uygulamasını açar.
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
            // "Aç" ipucu rozeti.
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Haritada Aç',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
