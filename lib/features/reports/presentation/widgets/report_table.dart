import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/report_models.dart';

/// Date · Sale · Received · Due table.
class ReportTable extends StatelessWidget {
  const ReportTable({super.key, required this.period, required this.rows});

  final ReportPeriod period;
  final List<ReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final head = theme.bodySmall?.copyWith(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w600,
    );
    final firstColumn = switch (period) {
      ReportPeriod.daily => 'Date',
      ReportPeriod.weekly => 'Week',
      ReportPeriod.monthly => 'Month',
    };

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Line(
            cells: [
              Text(firstColumn, style: head),
              Text('Sale', style: head),
              Text('Received', style: head),
              Text('Due', style: head),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Text(
                'No sales in this period.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              _RowLine(row: rows[i]),
            ],
        ],
      ),
    );
  }
}

class _RowLine extends StatelessWidget {
  const _RowLine({required this.row});
  final ReportRow row;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium;
    final money = body?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return _Line(
      cells: [
        Text(row.label, style: body?.copyWith(fontWeight: FontWeight.w600)),
        Text(Fmt.money(row.sales, empty: '${Fmt.taka}0'), style: money),
        Text(
          Fmt.money(row.received, empty: '${Fmt.taka}0'),
          style: money?.copyWith(color: AppColors.positive),
        ),
        Text(
          Fmt.money(row.due, empty: '${Fmt.taka}0'),
          style: money?.copyWith(
            color: row.due > 0 ? AppColors.negative : AppColors.positive,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// First cell left-aligned, the money cells right-aligned. Each cell
/// shrinks its text rather than wrapping when amounts are large.
class _Line extends StatelessWidget {
  const _Line({required this.cells});
  final List<Widget> cells;

  static const _flex = [5, 6, 6, 6];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              flex: _flex[i],
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: i == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: cells[i],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
