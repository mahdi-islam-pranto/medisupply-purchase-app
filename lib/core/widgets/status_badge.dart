import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BadgeTone { success, warning, danger, info, neutral }

/// Small pill label: "Done", "Needs price", "Pending", "5 of 8 approved"...
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  /// Builds a badge from an API status value
  /// (`needs_price`, `done`, `approved`, `rejected`, `pending`, `partial`).
  /// [label] overrides the default text, e.g. the server's `status_label`.
  factory StatusBadge.forStatus(String? status, {Key? key, String? label}) {
    final (tone, text) = switch (status) {
      'done' => (BadgeTone.success, 'Done'),
      'approved' => (BadgeTone.success, 'Approved'),
      'needs_price' => (BadgeTone.warning, 'Needs price'),
      'pending' => (BadgeTone.warning, 'Pending'),
      'partial' => (BadgeTone.info, 'Partly approved'),
      'rejected' => (BadgeTone.danger, 'Rejected'),
      _ => (BadgeTone.neutral, status ?? '—'),
    };
    return StatusBadge(key: key, label: label ?? text, tone: tone);
  }

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.success => (AppColors.primaryLight, AppColors.primaryDark),
      BadgeTone.warning => (AppColors.warningBg, AppColors.warningText),
      BadgeTone.danger => (AppColors.negativeLight, AppColors.negative),
      BadgeTone.info => (AppColors.infoBg, AppColors.infoText),
      BadgeTone.neutral => (AppColors.neutralBg, AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
