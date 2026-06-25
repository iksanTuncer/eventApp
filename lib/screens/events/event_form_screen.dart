import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_event.dart';
import '../../services/auth_provider.dart';
import '../../services/event_service.dart';
import '../../services/image_service.dart';
import '../../services/notification_queue_service.dart';
import '../../utils/constants.dart';
import '../../utils/strings.dart';
import '../../widgets/image_source_sheet.dart';
import '../../widgets/static_map.dart';
import 'invitee_picker_screen.dart';
import 'map_picker_screen.dart';

class EventFormScreen extends StatefulWidget {
  final EventType type;
  const EventFormScreen({super.key, required this.type});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _locationText = TextEditingController();
  final _noShowMessage = TextEditingController();

  final _imageService = ImageService();
  final _events = EventService();
  final _queue = NotificationQueueService();

  String? _imageBase64; // null ise hazır asset kullanılır
  DateTime? _startAt;
  DateTime? _endAt;
  String _locationMode = 'text'; // 'text' | 'map'
  double? _lat;
  double? _lng;
  String? _locationAddress;
  Set<String> _invitees = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Hazır tipte başlık ön-dolu gelir
    if (!widget.type.isCustom) {
      _title.text = widget.type.defaultTitle;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _locationText.dispose();
    _noShowMessage.dispose();
    super.dispose();
  }

  Future<void> _pickEventImage() async {
    final fromCamera = await showImageSourceSheet(context);
    if (fromCamera == null || !mounted) return;
    final res = await _imageService.pick(fromCamera: fromCamera);
    if (!mounted) return;
    switch (res.status) {
      case ImagePickStatus.success:
        setState(() => _imageBase64 = res.base64);
        break;
      case ImagePickStatus.tooLarge:
        _err(S.imageTooLarge);
        break;
      case ImagePickStatus.failed:
        _err(S.imagePickFailed);
        break;
      case ImagePickStatus.cancelled:
        break; // sessiz
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();

    // Bitiş seçmek için önce başlangıç gerekli.
    if (!isStart && _startAt == null) {
      _err(S.pickStartFirst);
      return;
    }

    // Bitişin alt sınırı: başlangıç ile "şimdi"nin büyüğü → hem başlangıçtan
    // önce hem de geçmişte tarih seçilmesini engeller (etkinliğin "Etkinliklerim"de
    // görünmesi için endAt > now ZORUNLU; aksi halde cron etkinliği siler).
    final DateTime firstAllowed =
        isStart ? now : (_startAt!.isAfter(now) ? _startAt! : now);
    final DateTime initial = isStart
        ? (_startAt ?? now)
        : (_endAt != null && _endAt!.isAfter(firstAllowed)
            ? _endAt!
            : firstAllowed);

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstAllowed,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (isStart) {
      setState(() {
        _startAt = dt;
        // Başlangıç ileri kayıp mevcut bitişi geçersiz kıldıysa bitişi sıfırla.
        if (_endAt != null && !_endAt!.isAfter(_startAt!)) _endAt = null;
      });
    } else {
      // Saat dahil: bitiş hem başlangıçtan hem de "şimdi"den sonra olmalı.
      if (!dt.isAfter(_startAt!)) {
        _err(S.endMustBeAfterStart);
        return;
      }
      if (!dt.isAfter(now)) {
        _err(S.endMustBeFuture);
        return;
      }
      setState(() => _endAt = dt);
    }
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(initialLat: _lat, initialLng: _lng),
      ),
    );
    if (result != null) {
      setState(() {
        _lat = result.lat;
        _lng = result.lng;
        _locationAddress = result.address;
        _locationMode = 'map';
      });
    }
  }

  Future<void> _pickInvitees() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => InviteePickerScreen(initial: _invitees),
      ),
    );
    if (result != null) setState(() => _invitees = result);
  }

  bool _validate() {
    if (_title.text.trim().isEmpty) {
      _err('${S.eventTitle} gerekli');
      return false;
    }
    if (_startAt == null || _endAt == null) {
      _err('Tarih/saat seç');
      return false;
    }
    if (!_endAt!.isAfter(_startAt!)) {
      _err(S.endMustBeAfterStart);
      return false;
    }
    // endAt geçmişte olursa etkinlik listede görünmez + cron siler. Engelle.
    if (!_endAt!.isAfter(DateTime.now())) {
      _err(S.endMustBeFuture);
      return false;
    }
    if (_locationMode == 'text' && _locationText.text.trim().isEmpty) {
      _err('Konum gir veya haritadan seç');
      return false;
    }
    if (_locationMode == 'map' && _lat == null) {
      _err('Haritadan konum seç');
      return false;
    }
    if (_invitees.isEmpty) {
      _err('En az bir davetli seç');
      return false;
    }
    return true;
  }

  void _err(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    final profile = auth.profile!;

    try {
      // Görsel: kullanıcı değiştirmediyse hazır asset'i base64'e çevirmek
      // yerine boş bırakırız; kart bunu asset olarak gösterir.
      final event = AppEvent(
        eventId: '',
        hostUid: profile.uid,
        hostUsername: profile.username,
        type: widget.type.key,
        title: _title.text.trim(),
        imageBase64: _imageBase64 ?? '', // boşsa kart asset gösterir
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        startAt: _startAt!,
        endAt: _endAt!,
        locationMode: _locationMode,
        locationText: _locationMode == 'text'
            ? _locationText.text.trim()
            : _locationAddress,
        lat: _locationMode == 'map' ? _lat : null,
        lng: _locationMode == 'map' ? _lng : null,
        inviteeUids: _invitees.toList(),
        noShowMessage: _noShowMessage.text.trim().isEmpty
            ? null
            : _noShowMessage.text.trim(),
      );

      final eventId = await _events.createEvent(event);

      // Davet bildirimini kuyruğa ekle (cron worker FCM gönderir)
      await _queue.enqueueInvite(
        targetUids: _invitees.toList(),
        hostUsername: profile.username,
        eventTitle: event.title,
        eventId: eventId,
      );

      if (mounted) {
        Navigator.popUntil(context, (r) => r.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Davetler gönderildi!')),
        );
      }
    } catch (e) {
      _err(S.errorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy, HH:mm', 'tr');
    return Scaffold(
      appBar: AppBar(title: Text(widget.type.label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Görsel
          _ImagePickerTile(
            imageBase64: _imageBase64,
            assetFallback: widget.type.isCustom ? null : widget.type.assetImage,
            onTap: _pickEventImage,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: S.eventTitle),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
          ),
          const SizedBox(height: 20),

          // Tarih/saat
          _PickerRow(
            label: S.startDate,
            value: _startAt == null ? '-' : df.format(_startAt!),
            onTap: () => _pickDateTime(true),
          ),
          _PickerRow(
            label: S.endDate,
            value: _endAt == null ? '-' : df.format(_endAt!),
            onTap: () => _pickDateTime(false),
          ),
          const SizedBox(height: 20),

          // Konum
          const Text(S.location,
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'text', label: Text('Metin')),
              ButtonSegment(value: 'map', label: Text('Harita')),
            ],
            selected: {_locationMode},
            onSelectionChanged: (s) =>
                setState(() => _locationMode = s.first),
          ),
          const SizedBox(height: 8),
          if (_locationMode == 'text')
            TextField(
              controller: _locationText,
              decoration: const InputDecoration(hintText: S.locationHint),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_lat != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: StaticMap(lat: _lat!, lng: _lng!, height: 150),
                  ),
                  const SizedBox(height: 6),
                  if (_locationAddress != null &&
                      _locationAddress!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.place,
                            size: 18, color: Color(0xFF6F4E37)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_locationAddress!)),
                      ],
                    ),
                  const SizedBox(height: 6),
                ],
                OutlinedButton.icon(
                  onPressed: _pickOnMap,
                  icon: const Icon(Icons.map),
                  label: Text(
                      _lat == null ? 'Haritadan Konum Seç' : 'Konumu Değiştir'),
                ),
              ],
            ),
          const SizedBox(height: 20),

          // Davetliler
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.group),
            title: const Text(S.invitees),
            subtitle: Text('${_invitees.length} kişi seçildi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickInvitees,
          ),
          const Divider(),

          // No-show mesajı
          const SizedBox(height: 8),
          const Text(S.noShowTitle,
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _noShowMessage,
            maxLines: 2,
            decoration: const InputDecoration(hintText: S.noShowHint),
          ),
          const SizedBox(height: 28),

          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text(S.sendInvites),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _PickerRow(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit_calendar),
      onTap: onTap,
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  final String? imageBase64;
  final String? assetFallback;
  final VoidCallback onTap;
  static const double height = 160;
  const _ImagePickerTile({
    required this.imageBase64,
    required this.assetFallback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (imageBase64 != null) {
      content = Image.memory(ImageService.decode(imageBase64!),
          fit: BoxFit.cover, width: double.infinity, height: height);
    } else if (assetFallback != null) {
      content = Image.asset(assetFallback!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          errorBuilder: (_, __, ___) => _placeholder(height));
    } else {
      content = _placeholder(height);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          // Tüm görsel/placeholder alanı tıklanabilir (sadece buton değil).
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                content,
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: FilledButton.tonalIcon(
                    onPressed: onTap,
                    icon: const Icon(Icons.photo_camera, size: 18),
                    label: const Text(S.changeImage),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(double h) => Container(
        height: h,
        width: double.infinity,
        color: const Color(0xFFE0D5C5),
        child: const Icon(Icons.add_photo_alternate,
            size: 40, color: Color(0xFF6F4E37)),
      );
}
