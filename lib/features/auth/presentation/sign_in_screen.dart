import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_logo.dart';

/// Screen 1 — Sign in.
/// Phase 1 placeholder: the real form is built in Phase 2.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context).textTheme;
    final expired = ref.watch(sessionProvider.select((s) => s.expired));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            const Center(child: AppLogo(size: 170)),
            const SizedBox(height: 16),
            Text(
              'Store Quote',
              textAlign: TextAlign.center,
              style: theme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to send your daily prices.',
              textAlign: TextAlign.center,
              style: theme.bodyLarge?.copyWith(color: AppColors.textMuted),
            ),
            if (expired) ...[
              const SizedBox(height: 16),
              Text(
                'Your session has ended. Please sign in again.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium?.copyWith(color: AppColors.negative),
              ),
            ],
            const SizedBox(height: 32),
            AppCard(
              child: Text(
                'The sign-in form is built in Phase 2.',
                style: theme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Preview app (debug only)',
                onPressed: () =>
                    ref.read(sessionProvider.notifier).debugPreview(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
