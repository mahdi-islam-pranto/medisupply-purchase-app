import 'package:flutter/material.dart';

import '../../../../core/models/quote_summary.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';

/// "Total outstanding due ৳184,500 — View report"
class TotalDueCard extends StatelessWidget {
  const TotalDueCard({
    super.key,
    required this.totalDue,
    required this.onViewReport,
  });

  final num totalDue;
  final VoidCallback onViewReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total outstanding due',
                  style: theme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Fmt.money(totalDue),
                    style: theme.headlineMedium?.copyWith(
                      color: totalDue > 0
                          ? AppColors.negative
                          : AppColors.positive,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewReport,
            child: const Text(
              'View report',
              style: TextStyle(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Last quote · 19 Nov · 5 of 8 approved · ৳63,925"
class LastQuoteCard extends StatelessWidget {
  const LastQuoteCard({super.key, required this.quote, this.onTap});

  final QuoteSummary quote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final date = quote.parsedDate;
    final parts = [
      date != null ? Fmt.dayMonth(date) : quote.dateLabel,
      quote.approvedText,
      quote.amountText,
    ];

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Last quote', style: theme.titleMedium),
                    const SizedBox(width: 10),
                    StatusBadge.forStatus(
                      quote.status,
                      label: quote.statusLabel.isEmpty
                          ? null
                          : quote.statusLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  parts.join(' · '),
                  style: theme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ],
      ),
    );
  }
}
