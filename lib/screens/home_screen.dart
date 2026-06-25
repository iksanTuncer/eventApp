import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_event.dart';
import '../services/auth_provider.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import '../utils/strings.dart';
import '../widgets/event_card.dart';
import 'events/event_type_picker_screen.dart';
import 'events/event_detail_screen.dart';
import 'missed_screen.dart';
import 'profile/edit_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _events = EventService();

  // Stream'ler bir kez oluşturulur; her build'de yeniden üretilirse
  // StreamBuilder her seferinde yeniden abone olup gereksiz Firestore
  // okuması yapar (ücretsiz kota koruması).
  late final String _uid;
  late final Stream<List<AppEvent>> _invited;
  late final Stream<List<AppEvent>> _hosted;
  NotificationService? _notif;

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthProvider>().firebaseUser!.uid;
    _invited = _events.invitedEvents(_uid);
    _hosted = _events.hostedEvents(_uid);
    // Açılışta sadece bildirim init. Süresi geçen etkinliklerin işlenmesi
    // (no-show FCM + silme) tamamen cron worker'a bırakıldı.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _notif = NotificationService();
      await _notif!.init(_uid);
    });
  }

  @override
  void dispose() {
    _notif?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(auth.profile?.username ?? S.appName),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: S.editProfile,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => auth.signOut(),
            ),
          ],
          bottom: const TabBar(
            isScrollable: false,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            // Seçili olmayan sekme kahverengi zeminde okunabilir olsun.
            unselectedLabelColor: Color(0xCCFFFFFF), // beyaz %80
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle:
                TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(text: S.myInvites),
              Tab(text: S.myEvents),
              Tab(text: S.missedTitle),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EventList(
              stream: _invited,
              emptyText: S.noInvites,
              isHost: false,
            ),
            _EventList(
              stream: _hosted,
              emptyText: S.noEvents,
              isHost: true,
            ),
            const MissedTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EventTypePickerScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text(S.createEvent),
        ),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final Stream<List<AppEvent>> stream;
  final String emptyText;
  final bool isHost;
  const _EventList({
    required this.stream,
    required this.emptyText,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppEvent>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Sorgu hatası (ör. eksik Firestore composite index) artık sessizce
        // boş liste gibi gösterilmez; gerçek sebep yüzeye çıkar.
        if (snap.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(S.loadFailed,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54)),
            ),
          );
        }
        final events = snap.data ?? [];
        if (events.isEmpty) {
          return Center(
            child: Text(emptyText,
                style: const TextStyle(color: Colors.black54)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: events.length,
          itemBuilder: (_, i) => EventCard(
            event: events[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailScreen(
                  eventId: events[i].eventId,
                  isHost: isHost,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
