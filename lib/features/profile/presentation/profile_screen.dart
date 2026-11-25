import 'package:flutter/material.dart';

import '../../shared/placeholder_tab.dart';

/// Screen 8 — Profile.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderTab(
    title: 'Profile',
    icon: Icons.person_outline_rounded,
    phase: 7,
  );
}
