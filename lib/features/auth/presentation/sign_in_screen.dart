import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/session/session_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_logo.dart';
import '../data/auth_repository.dart';

/// Screen 1 — Sign in with phone/email and App PIN.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _pinFocus = FocusNode();

  bool _loading = false;
  bool _showPin = false;
  String? _error; // general error shown above the button
  String? _loginError; // server-side field errors (422)
  String? _pinError;

  @override
  void initState() {
    super.initState();
    _prefillLastLogin();
  }

  Future<void> _prefillLastLogin() async {
    final last = await ref.read(sessionStorageProvider).readLastLogin();
    if (!mounted || last == null || _loginCtrl.text.isNotEmpty) return;
    _loginCtrl.text = last;
    _pinFocus.requestFocus();
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _pinCtrl.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _clearServerErrors() {
    if (_error == null && _loginError == null && _pinError == null) return;
    setState(() {
      _error = null;
      _loginError = null;
      _pinError = null;
    });
  }

  Future<void> _submit() async {
    if (_loading) return;
    _clearServerErrors();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final login = _loginCtrl.text.trim();
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(login: login, pin: _pinCtrl.text);

      await ref.read(sessionStorageProvider).saveLastLogin(login);
      TextInput.finishAutofillContext();
      // The router moves to Home as soon as the session changes.
      await ref
          .read(sessionProvider.notifier)
          .signIn(result.storeKey, result.store);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loginError = e.fieldError('login');
        _pinError = e.fieldError('pin');
        // Show the general message only if no field shows it already.
        _error = (_loginError == null && _pinError == null) ? e.message : null;
      });
      if (e.kind == ApiErrorKind.unauthorized) {
        _pinCtrl.clear();
        _pinFocus.requestFocus();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final expired = ref.watch(sessionProvider.select((s) => s.expired));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    const Center(child: AppLogo(size: 150)),
                    const SizedBox(height: 12),
                    Text(
                      'Store Quote',
                      textAlign: TextAlign.center,
                      style: theme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to send your daily prices.',
                      textAlign: TextAlign.center,
                      style: theme.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (expired && _error == null) ...[
                      const _Banner(
                        icon: Icons.lock_clock_outlined,
                        message:
                            'Your session has ended. Please sign in again.',
                      ),
                      const SizedBox(height: 16),
                    ],
                    _FieldLabel('Phone number or email'),
                    TextFormField(
                      controller: _loginCtrl,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [
                        AutofillHints.telephoneNumber,
                        AutofillHints.email,
                        AutofillHints.username,
                      ],
                      decoration: InputDecoration(
                        hintText: '01XXXXXXXXX',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        errorText: _loginError,
                      ),
                      validator: Validators.phoneOrEmail,
                      onChanged: (_) => _clearServerErrors(),
                      onFieldSubmitted: (_) => _pinFocus.requestFocus(),
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel('App PIN'),
                    TextFormField(
                      controller: _pinCtrl,
                      focusNode: _pinFocus,
                      enabled: !_loading,
                      obscureText: !_showPin,
                      obscuringCharacter: '●',
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: '●●●●●●',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        errorText: _pinError,
                        suffixIcon: IconButton(
                          tooltip: _showPin ? 'Hide PIN' : 'Show PIN',
                          icon: Icon(
                            _showPin
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(() => _showPin = !_showPin),
                        ),
                      ),
                      validator: (v) =>
                          Validators.required(v, 'Enter your App PIN'),
                      onChanged: (_) => _clearServerErrors(),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      _Banner(
                        icon: Icons.error_outline_rounded,
                        message: _error!,
                      ),
                      const SizedBox(height: 16),
                    ],
                    PrimaryButton(
                      label: 'Sign in',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 28),
                    AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Quotes are accepted only during your daily '
                              'quote window.',
                              style: theme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: AppColors.textMuted),
    ),
  );
}

/// Soft red message box for sign-in problems.
class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.negativeLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.negative),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.negative),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
