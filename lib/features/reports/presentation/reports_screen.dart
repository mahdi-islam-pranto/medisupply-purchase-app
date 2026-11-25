import 'package:flutter/material.dart';

import '../../shared/placeholder_tab.dart';

/// Screen 7 — Sales & collection.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderTab(
    title: 'Sales & collection',
    icon: Icons.bar_chart_outlined,
    phase: 6,
  );
}
