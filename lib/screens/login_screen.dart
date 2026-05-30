import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

/// Role-based login. Pick a user and enter their PIN.
/// Demo PINs: Owner 1111 • Manager 2222 • Staff 3333
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AppUser? _selected;
  final _pin = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _selected ??= auth.users.isNotEmpty ? auth.users.first : null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.brandGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_person,
                        size: 56, color: AppTheme.primary),
                    const SizedBox(height: 8),
                    Text('Sign in to PitStock',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Role-based access',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(.6))),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      children: auth.users
                          .map((u) => ChoiceChip(
                                label: Text('${u.name} (${u.role.label})'),
                                selected: _selected?.id == u.id,
                                onSelected: (_) =>
                                    setState(() => _selected = u),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pin,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        errorText: _error,
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _login(auth),
                        child: const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Demo PINs: Owner 1111 • Manager 2222 • Staff 3333',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(.5))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login(AuthProvider auth) {
    if (_selected == null) return;
    final ok = auth.login(_selected!.id, _pin.text.trim());
    if (ok) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeShell()));
    } else {
      setState(() => _error = 'Incorrect PIN');
    }
  }
}
