import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_event.dart';
import '../../models/app_user.dart';
import '../../services/auth_provider.dart';
import '../../services/event_service.dart';
import '../../services/image_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/strings.dart';
import '../../widgets/static_map.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final bool isHost;
  const EventDetailScreen(
      {super.key, required this.eventId, required this.isHost});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _events = EventService();
  final _users = UserService();
  AppEvent? _event;
  String? _myStatus;
  // Host görünümünde RSVP listelerinde fotoğraf göstermek için davetli profilleri.
  Map<String, AppUser> _inviteeUsers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Capture uid synchronously (before any await) to avoid using context
    // across an async gap.
    final uid =
        widget.isHost ? null : context.read<AuthProvider>().firebaseUser!.uid;
    final e = await _events.getEvent(widget.eventId);
    String? mine;
    if (uid != null) {
      mine = await _events.myRsvpStatus(widget.eventId, uid);
    }
    // Host görünümünde davetli fotoğraf+adlarını listelemek için profilleri çek.
    Map<String, AppUser> users = {};
    if (widget.isHost && e != null && e.inviteeUids.isNotEmpty) {
      users = await _users.getUsersByUids(e.inviteeUids);
    }
    if (!mounted) return;
    setState(() {
      _event = e;
      _myStatus = mine;
      _inviteeUsers = users;
      _loading = false;
    });
  }

  Future<void> _respond(String status) async {
    final auth = context.read<AuthProvider>();
    await _events.respond(
      widget.eventId,
      auth.firebaseUser!.uid,
      auth.profile!.username,
      status,
    );
    if (!mounted) return;
    setState(() => _myStatus = status);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cevabın kaydedildi')),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(S.deleteEvent),
        content: const Text('Bu etkinlik ve tüm verileri silinecek. Emin misin?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(S.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(S.deleteEvent)),
        ],
      ),
    );
    if (ok == true) {
      await _events.deleteEventDeep(widget.eventId);
      if (mounted) Navigator.pop(context);
    }
  }

  /// Konumu cihazın harita uygulamasında açar (yol tarifi). API key gerektirmez.
  Future<void> _openInMaps(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harita uygulaması açılamadı')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_event == null) {
      return const Scaffold(body: Center(child: Text('Etkinlik bulunamadı')));
    }
    final e = _event!;
    final type = EventTypes.byKey(e.type);
    final df = DateFormat('d MMMM yyyy, HH:mm', 'tr');

    return Scaffold(
      appBar: AppBar(
        title: Text(e.title),
        actions: [
          if (widget.isHost)
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        children: [
          // Görsel
          if (e.imageBase64.isNotEmpty)
            Image.memory(ImageService.decode(e.imageBase64),
                height: 200, width: double.infinity, fit: BoxFit.cover)
          else
            Container(
              height: 200,
              width: double.infinity,
              color: const Color(0xFFF5EBDD),
              child: Image.asset(type.assetImage,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                      height: 200, color: const Color(0xFFE0D5C5))),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.local_cafe, type.label),
                _infoRow(Icons.person, 'Düzenleyen: ${e.hostUsername}'),
                _infoRow(Icons.play_arrow, 'Başlangıç: ${df.format(e.startAt)}'),
                _infoRow(Icons.stop, 'Bitiş: ${df.format(e.endAt)}'),
                _infoRow(
                  Icons.place,
                  (e.locationText != null && e.locationText!.isNotEmpty)
                      ? e.locationText!
                      : (e.locationMode == 'map' ? 'Harita konumu' : '-'),
                ),
                if (e.description != null) ...[
                  const SizedBox(height: 8),
                  Text(e.description!),
                ],
                if (e.locationMode == 'map' &&
                    e.lat != null &&
                    e.lng != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: StaticMap(
                      lat: e.lat!,
                      lng: e.lng!,
                      height: 170,
                      onTap: () => _openInMaps(e.lat!, e.lng!),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openInMaps(e.lat!, e.lng!),
                    icon: const Icon(Icons.directions),
                    label: const Text('Haritada Aç / Yol Tarifi'),
                  ),
                ],
                const SizedBox(height: 20),

                // Davetli ise RSVP butonları
                if (!widget.isHost) _rsvpSection(),

                // Host ise katılımcı listeleri
                if (widget.isHost) _hostRsvpLists(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6F4E37)),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );

  Widget _rsvpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(S.yourResponse,
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _myStatus == RsvpStatus.yes
                      ? Colors.green
                      : Colors.grey.shade400,
                ),
                onPressed: () => _respond(RsvpStatus.yes),
                icon: const Icon(Icons.check),
                label: const Text(S.willAttend),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _myStatus == RsvpStatus.no
                      ? Colors.red
                      : Colors.grey.shade400,
                ),
                onPressed: () => _respond(RsvpStatus.no),
                icon: const Icon(Icons.close),
                label: const Text(S.wontAttend),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _hostRsvpLists() {
    return StreamBuilder<List<Rsvp>>(
      stream: _events.rsvpStream(widget.eventId),
      builder: (context, snap) {
        final rsvps = snap.data ?? [];
        final yes = rsvps.where((r) => r.status == RsvpStatus.yes).toList();
        final no = rsvps.where((r) => r.status == RsvpStatus.no).toList();
        final pending =
            rsvps.where((r) => r.status == RsvpStatus.pending).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rsvpGroup(S.attending, yes, Colors.green),
            _rsvpGroup(S.notAttending, no, Colors.red),
            _rsvpGroup(S.pending, pending, Colors.grey),
          ],
        );
      },
    );
  }

  Widget _rsvpGroup(String title, List<Rsvp> list, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(
                color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('$title (${list.length})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 18, top: 2),
            child: Text('—', style: TextStyle(color: Colors.black45)),
          )
        else
          ...list.map(_rsvpTile),
      ],
    );
  }

  /// Tek bir RSVP satırı: fotoğraf + kullanıcı adı (alt alta listelenir).
  Widget _rsvpTile(Rsvp r) {
    final user = _inviteeUsers[r.uid];
    final photo = user?.photoBase64;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final name =
        r.username.isNotEmpty ? r.username : (user?.username ?? '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE0D5C5),
            backgroundImage:
                hasPhoto ? MemoryImage(ImageService.decode(photo)) : null,
            child: hasPhoto
                ? null
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Color(0xFF6F4E37),
                        fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name.isEmpty ? '—' : name)),
        ],
      ),
    );
  }
}
