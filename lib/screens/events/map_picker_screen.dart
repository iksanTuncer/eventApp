import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/location_service.dart';

/// Harita üzerinde seçilen konum (WhatsApp tarzı konum paylaşımı).
class PickedLocation {
  final double lat;
  final double lng;
  final String address;
  PickedLocation(this.lat, this.lng, this.address);
}

/// OpenStreetMap tabanlı interaktif konum seçici (ücretsiz, API key gerektirmez).
/// Haritayı kaydır → ortadaki sabit pin konumu işaretler → adres otomatik gelir.
class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final _map = MapController();
  static const _fallback = LatLng(41.0082, 28.9784); // İstanbul
  LatLng _center = _fallback;
  String _address = '';
  bool _loadingAddr = false;
  bool _ready = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    LatLng start = _fallback;
    if (widget.initialLat != null && widget.initialLng != null) {
      start = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      final pos = await LocationService.getCurrent();
      if (pos != null) start = LatLng(pos.latitude, pos.longitude);
    }
    if (!mounted) return;
    setState(() {
      _center = start;
      _ready = true;
    });
    _reverseGeocode(start);
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _center = camera.center;
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), () => _reverseGeocode(_center));
  }

  Future<void> _reverseGeocode(LatLng p) async {
    setState(() => _loadingAddr = true);
    String addr = '';
    try {
      final marks = await placemarkFromCoordinates(p.latitude, p.longitude);
      if (marks.isNotEmpty) {
        final m = marks.first;
        addr = [m.street, m.subLocality, m.locality, m.administrativeArea]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
      }
    } catch (_) {
      // Geocoder yoksa/çevrimdışıysa adres boş kalır; koordinat yine kaydedilir.
    }
    if (!mounted) return;
    setState(() {
      _address = addr;
      _loadingAddr = false;
    });
  }

  Future<void> _goToMyLocation() async {
    final pos = await LocationService.getCurrent();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum izni gerekli')),
        );
      }
      return;
    }
    final p = LatLng(pos.latitude, pos.longitude);
    _map.move(p, 16);
    _center = p;
    _reverseGeocode(p);
  }

  void _confirm() {
    Navigator.pop(
      context,
      PickedLocation(
        _center.latitude,
        _center.longitude,
        _address.isNotEmpty ? _address : 'Seçili konum',
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konum Seç')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 16,
                    onPositionChanged: _onPositionChanged,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.eventapp.event_app',
                    ),
                  ],
                ),
                // Sabit merkez pin (WhatsApp tarzı — harita altından kayar)
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.location_pin,
                          size: 50, color: Color(0xFFC8853A)),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 150,
                  child: FloatingActionButton.small(
                    heroTag: 'myloc',
                    onPressed: _goToMyLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.place,
                                  color: Color(0xFF6F4E37)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _loadingAddr
                                    ? const Text('Adres alınıyor...')
                                    : Text(
                                        _address.isNotEmpty
                                            ? _address
                                            : "Haritayı kaydır, pin'i konuma getir",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: _confirm,
                            icon: const Icon(Icons.check),
                            label: const Text('Bu Konumu Seç'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
