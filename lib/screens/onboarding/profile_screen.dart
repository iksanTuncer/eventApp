import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/image_service.dart';
import '../../services/user_service.dart';
import '../../utils/strings.dart';
import '../../widgets/image_source_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _username = TextEditingController();
  final _imageService = ImageService();
  final _users = UserService();
  String? _photoBase64;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final fromCamera = await showImageSourceSheet(context);
    if (fromCamera == null || !mounted) return;
    final res = await _imageService.pick(fromCamera: fromCamera);
    if (!mounted) return;
    if (res.ok) {
      setState(() => _photoBase64 = res.base64);
    } else if (res.status == ImagePickStatus.tooLarge) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.imageTooLarge)));
    } else if (res.status == ImagePickStatus.failed) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.imagePickFailed)));
    }
  }

  Future<void> _save() async {
    final name = _username.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.usernameRequired)));
      return;
    }
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    try {
      await _users.updateProfile(
        auth.firebaseUser!.uid,
        username: name,
        photoBase64: _photoBase64,
      );
      // reloadProfile sonrası _Root, username dolu olduğu için ilgi seçim
      // ekranına yönlendirir. Hata olursa kullanıcı sessiz kalmasın.
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
    return Scaffold(
      appBar: AppBar(title: const Text(S.profileTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: const Color(0xFFE0D5C5),
                  backgroundImage: _photoBase64 != null
                      ? MemoryImage(ImageService.decode(_photoBase64!))
                      : null,
                  child: _photoBase64 == null
                      ? const Icon(Icons.add_a_photo,
                          size: 32, color: Color(0xFF6F4E37))
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
                child: Text(S.addPhoto,
                    style: TextStyle(color: Colors.black54))),
            const SizedBox(height: 28),
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: S.username),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text(S.next),
            ),
          ],
        ),
      ),
    );
  }
}
