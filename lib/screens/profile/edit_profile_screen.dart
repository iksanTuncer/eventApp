import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../services/user_service.dart';
import '../../utils/strings.dart';
import '../../widgets/image_source_sheet.dart';

/// Mevcut profili (kullanıcı adı + fotoğraf) düzenler.
/// Ana ekrandan erişilir; onboarding'deki ProfileScreen'den farklı olarak
/// alanları mevcut değerlerle ön-doldurur ve kaydedince geri döner.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _username = TextEditingController();
  final _imageService = ImageService();
  final _users = UserService();
  String? _photoBase64;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _username.text = profile?.username ?? '';
    _photoBase64 = profile?.photoBase64;
  }

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
      await auth.reloadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.profileSaved)));
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(S.errorGeneric)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    // 1) Geri alınamaz uyarısı + onay.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.deleteAccountTitle),
        content: const Text(S.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(S.deleteAccount),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // 2) Şifre iste (Firebase hesap silmeyi yakın giriş ister → reauthenticate).
    final passCtrl = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.deleteAccountTitle),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: S.deleteAccountPasswordPrompt),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, passCtrl.text),
            child: const Text(S.confirm),
          ),
        ],
      ),
    );
    if (password == null || password.isEmpty || !mounted) return;

    // 3) Sil. authState değişimi root'u giriş ekranına döndürür.
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.deleteAccount(password);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AuthService.messageFor(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.editProfileTitle)),
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
            Center(
              child: TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera, size: 18),
                label: const Text(S.changePhoto),
              ),
            ),
            const SizedBox(height: 20),
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
                  : const Text(S.save),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _busy ? null : _deleteAccount,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                S.deleteAccount,
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
