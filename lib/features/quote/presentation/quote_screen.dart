import 'package:flutter/material.dart';

import '../../shared/placeholder_tab.dart';

/// Screens 3 & 4 — Products to quote.
class QuoteScreen extends StatelessWidget {
  const QuoteScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderTab(
    title: 'Products to quote',
    icon: Icons.edit_note_outlined,
    phase: 4,
  );
}
