import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

enum MoneyTone { neutral, positive, negative }

/// "Sales ৳63,925" style tile, used in a row of three on Home and Reports.
class MoneyTile extends StatelessWidget {
  const MoneyTile({
    super.key,
    required this.label,
    required this.amount,
    this.tone = MoneyTone.neutral,
  });

  final String label;
  final num? amount;
  final MoneyTone tone;

  static Color colorFor(MoneyTone tone) => switch (tone) {
    MoneyTone.neutral => AppColors.text,
    MoneyTone.positive => AppColors.positive,
    MoneyTone.negative => AppColors.negative,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Fmt.money(amount),
              style: theme.titleLarge?.copyWith(color: colorFor(tone)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sales / Received / Due in a row.
class MoneySummaryRow extends StatelessWidget {
  const MoneySummaryRow({
    super.key,
    required this.sales,
    required this.received,
    required this.due,
  });

  final num? sales;
  final num? received;
  final num? due;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MoneyTile(label: 'Sales', amount: sales),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MoneyTile(
            label: 'Received',
            amount: received,
            tone: MoneyTone.positive,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MoneyTile(
            label: 'Due',
            amount: due,
            tone: (due ?? 0) > 0 ? MoneyTone.negative : MoneyTone.positive,
          ),
        ),
      ],
    );
  }
}
