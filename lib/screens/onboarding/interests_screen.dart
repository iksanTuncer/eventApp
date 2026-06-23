import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/strings.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});
  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final _users = UserService();
  final Set<String> _selected = {};
  bool _busy = false;

  Future<void> _finish() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir tane seç')),
      );
      return;
    }
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    try {
      await _users.updateProfile(
        auth.firebaseUser!.uid,
        interests: _selected.toList(),
      );
      await auth.reloadProfile();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(S.saveFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // "Diğer" hariç hazır tipler ilgi alanı olarak gösterilir
    final types = EventTypes.all.where((t) => !t.isCustom).toList();
    return Scaffold(
      appBar: AppBar(title: const Text(S.interestsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(S.interestsSubtitle,
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: types.map((t) {
                final sel = _selected.contains(t.key);
                return FilterChip(
                  label: Text(t.label),
                  selected: sel,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selected.add(t.key);
                    } else {
                      _selected.remove(t.key);
                    }
                  }),
                );
              }).toList(),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : _finish,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text(S.finish),
            ),
          ],
        ),
      ),
    );
  }
}
