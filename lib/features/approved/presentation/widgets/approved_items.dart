import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/approved_models.dart';

/// Rows of approved products followed by a Total row.
class ApprovedItemsList extends StatelessWidget {
  const ApprovedItemsList({
    super.key,
    required this.items,
    required this.total,
  });

  final List<ApprovedItem> items;
  final num total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items) ...[_ItemRow(item: item), const Divider()],
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Expanded(child: Text('Total', style: theme.titleLarge)),
              Text(Fmt.money(total), style: theme.titleLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final ApprovedItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${Fmt.money(item.unitPrice)} × ${Fmt.number(item.qty)}',
                  style: theme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Fmt.money(item.total),
            style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
