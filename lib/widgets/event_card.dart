import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_event.dart';
import '../services/image_service.dart';
import '../utils/constants.dart';

class EventCard extends StatelessWidget {
  final AppEvent event;
  final VoidCallback onTap;
  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = EventTypes.byKey(event.type);
    final df = DateFormat('d MMM, HH:mm', 'tr');

    Widget image;
    if (event.imageBase64.isNotEmpty) {
      image = Image.memory(
        ImageService.decode(event.imageBase64),
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      image = Container(
        height: 140,
        width: double.infinity,
        color: const Color(0xFFF5EBDD),
        child: Image.asset(
          type.assetImage,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            height: 140,
            color: const Color(0xFFE0D5C5),
            child: const Icon(Icons.local_cafe, size: 48),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            image,
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Chip(
                        label: Text(type.label,
                            style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text('${df.format(event.startAt)} → ${df.format(event.endAt)}',
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          (event.locationText != null &&
                                  event.locationText!.isNotEmpty)
                              ? event.locationText!
                              : (event.locationMode == 'map'
                                  ? 'Harita konumu'
                                  : '-'),
                          style: const TextStyle(color: Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
