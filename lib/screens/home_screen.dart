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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _events = EventService();

  @override
  void initState() {
    super.initState();
    // Açılışta sadece bildirim init. Süresi geçen etkinliklerin işlenmesi
    // (no-show FCM + silme) tamamen cron worker'a bırakıldı; istemci silmesi
    // FCM gönderemediği için no-show bildirimini engelliyordu.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = context.read<AuthProvider>().firebaseUser!.uid;
      await NotificationService().init(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.firebaseUser!.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(auth.profile?.username ?? S.appName),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => auth.signOut(),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            tabs: [
              Tab(text: S.myInvites),
              Tab(text: S.myEvents),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EventList(
              stream: _events.invitedEvents(uid),
              emptyText: S.noInvites,
              isHost: false,
            ),
            _EventList(
              stream: _events.hostedEvents(uid),
              emptyText: S.noEvents,
              isHost: true,
            ),
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
