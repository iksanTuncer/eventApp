import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/auth_provider.dart';
import '../../services/user_service.dart';
import '../../utils/strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  final _users = UserService();

  bool _isRegister = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (_isRegister) {
        final cred = await _auth.register(_email.text, _password.text);
        // Boş profil oluştur (username onboarding'de)
        await _users.createUser(AppUser(
          uid: cred.user!.uid,
          email: _email.text.trim(),
          username: '',
        ));
      } else {
        await _auth.login(_email.text, _password.text);
      }
      if (mounted) {
        await context.read<AuthProvider>().reloadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.messageFor(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.coffee, size: 72, color: Color(0xFF6F4E37)),
                  const SizedBox(height: 12),
                  Text(S.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: S.email),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? S.invalidEmail
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: S.password),
                    validator: (v) => (v == null || v.length < 6)
                        ? S.passwordTooShort
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isRegister ? S.register : S.login),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _isRegister = !_isRegister),
                    child: Text(_isRegister ? S.haveAccount : S.noAccount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
