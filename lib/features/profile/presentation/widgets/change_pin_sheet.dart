import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/snackbars.dart';
import '../../data/profile_repository.dart';

/// Opens the Change PIN sheet. Shows a snackbar when the PIN is changed.
Future<void> showChangePinSheet(BuildContext context) async {
  final message = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const ChangePinSheet(),
  );
  if (message != null && context.mounted) {
    showAppSnackBar(context, message);
  }
}

/// Current / new / confirm PIN → `POST /change-pin`.
/// Pops with the success message.
class ChangePinSheet extends ConsumerStatefulWidget {
  const ChangePinSheet({super.key});

  @override
  ConsumerState<ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends ConsumerState<ChangePinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPin = TextEditingController();
  final _confirm = TextEditingController();

  bool _show = false;
  bool _saving = false;

  /// Messages from the server (422), shown under each field.
  Map<String, String?> _serverErrors = const {};
  String? _generalError;

  @override
  void dispose() {
    _current.dispose();
    _newPin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _serverErrors = const {};
      _generalError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final message = await ref
          .read(profileRepositoryProvider)
          .changePin(
            currentPin: _current.text,
            newPin: _newPin.text,
            confirmPin: _confirm.text,
          );
      if (mounted) Navigator.of(context).pop(message);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.kind == ApiErrorKind.validation && e.fieldErrors.isNotEmpty) {
        setState(() {
          _serverErrors = {
            'current_pin': e.fieldError('current_pin'),
            // Laravel puts "confirmation does not match" on new_pin.
            'new_pin': e.fieldError('new_pin'),
            'new_pin_confirmation': e.fieldError('new_pin_confirmation'),
          };
          final known = _serverErrors.values.any((m) => m != null);
          if (!known) _generalError = e.message;
        });
      } else {
        setState(() => _generalError = e.message);
      }
    } catch (e) {
      if (mounted) setState(() => _generalError = errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text('Change PIN', style: theme.titleLarge)),
                  IconButton(
                    tooltip: _show ? 'Hide PINs' : 'Show PINs',
                    onPressed: () => setState(() => _show = !_show),
                    icon: Icon(
                      _show
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Use at least 6 characters. You stay signed in on this phone.',
                style: theme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              _PinField(
                controller: _current,
                label: 'Current PIN',
                show: _show,
                serverError: _serverErrors['current_pin'],
                validator: (v) =>
                    Validators.required(v, 'Enter your current PIN'),
                autofocus: true,
              ),
              const SizedBox(height: 14),
              _PinField(
                controller: _newPin,
                label: 'New PIN',
                show: _show,
                serverError: _serverErrors['new_pin'],
                validator: (v) {
                  final err = Validators.newPin(v);
                  if (err != null) return err;
                  if (v == _current.text) {
                    return 'New PIN must be different from the current one';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _PinField(
                controller: _confirm,
                label: 'Confirm new PIN',
                show: _show,
                serverError: _serverErrors['new_pin_confirmation'],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter the new PIN again';
                  if (v != _newPin.text) return 'PINs do not match';
                  return null;
                },
                onSubmitted: (_) => _submit(),
                last: true,
              ),
              if (_generalError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _generalError!,
                  style: theme.bodyMedium?.copyWith(color: AppColors.negative),
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Save new PIN',
                loading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    required this.show,
    required this.validator,
    this.serverError,
    this.onSubmitted,
    this.autofocus = false,
    this.last = false,
  });

  final TextEditingController controller;
  final String label;
  final bool show;
  final FormFieldValidator<String> validator;
  final String? serverError;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      obscureText: !show,
      enableSuggestions: false,
      autocorrect: false,
      // Same keyboard as sign-in: PINs may contain letters.
      keyboardType: TextInputType.visiblePassword,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      // Server message (422) shown under the field until the next submit.
      forceErrorText: serverError,
      decoration: InputDecoration(labelText: label, errorMaxLines: 2),
    );
  }
}
