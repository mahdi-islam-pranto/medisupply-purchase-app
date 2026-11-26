import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/report_models.dart';

/// Daily · Weekly · Monthly segmented control.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final p in ReportPeriod.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: p == selected,
                child: Material(
                  color: p == selected
                      ? AppColors.primaryLight
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: p == selected ? null : () => onChanged(p),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Center(
                        child: Text(
                          p.label,
                          style: theme.labelLarge?.copyWith(
                            color: p == selected
                                ? AppColors.primaryDark
                                : AppColors.textMuted,
                            fontWeight: p == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
