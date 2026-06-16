import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/missed_event.dart';
import '../services/auth_provider.dart';
import '../services/event_service.dart';
import '../services/image_service.dart';
import '../utils/constants.dart';
import '../utils/strings.dart';

/// "Kaçırdıklarım" — süresi geçip silinen ama kullanıcının kaçırdığı
/// (no/pending) etkinliklerin görseli + no-show mesajı.
/// Cron worker, etkinliği silmeden önce bu kayıtları users/{uid}/missed
/// altına yazar (push ~4KB sınırına görsel sığmadığı için uygulama içinde gösterilir).
class MissedScreen extends StatelessWidget {
  const MissedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final events = EventService();

    return Scaffold(
      appBar: AppBar(title: const Text(S.missedTitle)),
      body: StreamBuilder<List<MissedEvent>>(
        stream: events.missedEvents(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(S.noMissed,
                  style: TextStyle(color: Colors.black54)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) => _MissedCard(
              missed: items[i],
              onDismiss: () => events.dismissMissed(uid, items[i].eventId),
            ),
          );
        },
      ),
    );
  }
}

class _MissedCard extends StatelessWidget {
  final MissedEvent missed;
  final VoidCallback onDismiss;
  const _MissedCard({required this.missed, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImage(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  missed.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (missed.hostUsername.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('${S.missedHostLabel}: ${missed.hostUsername}',
                      style: const TextStyle(color: Colors.black54)),
                ],
                if (missed.noShowMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E9DD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(missed.noShowMessage),
                  ),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text(S.missedDismiss),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    const double h = 160;
    if (missed.imageBase64.isNotEmpty) {
      return Image.memory(
        ImageService.decode(missed.imageBase64),
        height: h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetImage(h),
      );
    }
    return _assetImage(h);
  }

  Widget _assetImage(double h) {
    final asset = EventTypes.byKey(missed.type).assetImage;
    return Image.asset(
      asset,
      height: h,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: h,
        color: const Color(0xFFE0D5C5),
        child: const Icon(Icons.image_not_supported,
            size: 40, color: Color(0xFF6F4E37)),
      ),
    );
  }
}
