import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_buttons.dart';
import '../../auth/data/auth_actions.dart';
import '../../shared/placeholder_tab.dart';

/// Screen 8 — Profile. Full screen comes in Phase 7;
/// for now it only has Log out so sign-in can be tested.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => PlaceholderTab(
    title: 'Profile',
    icon: Icons.person_outline_rounded,
    phase: 7,
    footer: SecondaryButton(
      label: 'Log out',
      danger: true,
      onPressed: () => _confirmLogout(context, ref),
    ),
  );

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need your App PIN to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true) await logOut(ref);
  }
}
