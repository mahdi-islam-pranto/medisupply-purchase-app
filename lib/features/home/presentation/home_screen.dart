import 'package:flutter/material.dart';

import '../../shared/placeholder_tab.dart';

/// Screen 2 — Home.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderTab(title: 'Home', icon: Icons.home_outlined, phase: 3);
}
