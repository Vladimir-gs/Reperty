import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _googleBusy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(_email.text, _password.text);
    } on Exception catch (e) {
      setState(() => _error = 'No se pudo iniciar sesión. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _googleBusy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on Exception catch (e) {
      setState(() => _error = 'No se pudo entrar con Google. $e');
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrandNight(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppTheme.screenPadding + 8),
            children: [
              const SizedBox(height: 40),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandBlue.withAlpha(90),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.music_note_2,
                  size: 44,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Reperty',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'El repertorio de tu grupo,\nsiempre contigo.',
                style: TextStyle(fontSize: 17, color: AppTheme.iosGrey),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Continuar con Google',
                loading: _googleBusy,
                onPressed: _google,
              ),
              const SizedBox(height: 28),
              const Row(
                children: [
                  Expanded(
                    child: Divider(color: Color(0xFF38383A)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'o con email',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.iosGrey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Color(0xFF38383A)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _form,
                child: Column(
                  children: [
                    _DarkField(controller: _email, placeholder: 'Email'),
                    const SizedBox(height: 12),
                    _DarkField(
                      controller: _password,
                      placeholder: 'Contraseña',
                      obscure: true,
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const CupertinoActivityIndicator()
                    : const Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 17,
                          color: CupertinoColors.white,
                        ),
                      ),
              ),
              CupertinoButton(
                onPressed: () => context.go('/register'),
                child: const Text(
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.iosGrey,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.controller,
    required this.placeholder,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscure,
      style: const TextStyle(color: CupertinoColors.white, fontSize: 17),
      placeholderStyle: const TextStyle(color: AppTheme.iosGrey),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withAlpha(200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38383A)),
      ),
    );
  }
}
