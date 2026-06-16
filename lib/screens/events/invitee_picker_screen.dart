import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../services/auth_provider.dart';
import '../../services/image_service.dart';
import '../../services/user_service.dart';
import '../../utils/strings.dart';

/// Kullanıcı listesinden davetli seçer. Seçilen uid'leri geri döndürür.
class InviteePickerScreen extends StatefulWidget {
  final Set<String> initial;
  const InviteePickerScreen({super.key, this.initial = const {}});

  @override
  State<InviteePickerScreen> createState() => _InviteePickerScreenState();
}

class _InviteePickerScreenState extends State<InviteePickerScreen> {
  final _users = UserService();
  late Set<String> _selected;
  List<AppUser> _all = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initial};
    _load();
  }

  Future<void> _load() async {
    final myUid = context.read<AuthProvider>().firebaseUser!.uid;
    final list = await _users.listOtherUsers(myUid);
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _all
        .where((u) =>
            u.username.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.selectInvitees),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: Text('${S.save} (${_selected.length})',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Kullanıcı ara',
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final u = filtered[i];
                      final sel = _selected.contains(u.uid);
                      return CheckboxListTile(
                        value: sel,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(u.uid);
                          } else {
                            _selected.remove(u.uid);
                          }
                        }),
                        secondary: CircleAvatar(
                          backgroundColor: const Color(0xFFE0D5C5),
                          backgroundImage: u.photoBase64 != null
                              ? MemoryImage(
                                  ImageService.decode(u.photoBase64!))
                              : null,
                          child: u.photoBase64 == null
                              ? Text(u.username.isNotEmpty
                                  ? u.username[0].toUpperCase()
                                  : '?')
                              : null,
                        ),
                        title: Text(u.username),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
