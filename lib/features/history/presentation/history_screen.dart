import 'package:flutter/material.dart';

import '../../shared/placeholder_tab.dart';

/// Screen 6 — Quote history.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderTab(
    title: 'Quote history',
    icon: Icons.history_outlined,
    phase: 5,
  );
}
