import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Etkileşimsiz küçük harita önizlemesi (OpenStreetMap, ücretsiz).
/// Verilen konuma bir pin koyar. Form önizlemesi ve etkinlik detayında kullanılır.
class StaticMap extends StatelessWidget {
  final double lat;
  final double lng;
  final double height;
  const StaticMap({
    super.key,
    required this.lat,
    required this.lng,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final p = LatLng(lat, lng);
    return SizedBox(
      height: height,
      child: FlutterMap(
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
      ),
    );
  }
}
