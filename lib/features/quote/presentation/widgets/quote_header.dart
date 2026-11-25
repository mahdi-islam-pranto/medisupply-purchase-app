import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/countdown.dart';
import '../../../../core/widgets/window_chip.dart';
import '../../data/quote_models.dart';

/// Green header of Screen 3: store, title, window chip, countdown, progress.
class QuoteOpenHeader extends StatelessWidget {
  const QuoteOpenHeader({
    super.key,
    required this.data,
    required this.storeName,
    required this.onWindowChanged,
  });

  final QuoteData data;
  final String? storeName;
  final VoidCallback onWindowChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final total = data.total == 0 ? data.products.length : data.total;
    final progress = total == 0 ? 0.0 : (data.priced / total).clamp(0.0, 1.0);
    final white = Colors.white;
    final whiteSoft = Colors.white.withValues(alpha: 0.85);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: AppColors.primary,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (storeName != null && storeName!.isNotEmpty)
                  Text(
                    storeName!,
                    style: theme.bodyMedium?.copyWith(color: whiteSoft),
                  ),
                const SizedBox(height: 2),
                Text(
                  'Products to quote',
                  style: theme.headlineMedium?.copyWith(
                    color: white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: WindowChip(label: data.window.label, open: true),
                    ),
                    const SizedBox(width: 12),
                    Countdown(
                      deadline: data.window.deadline,
                      onDone: onWindowChanged,
                      builder: (context, s) => Text(
                        '${Fmt.countdown(s)} left',
                        style: theme.titleMedium?.copyWith(
                          color: white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          color: white,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${data.priced} of $total priced',
                      style: theme.bodyMedium?.copyWith(color: whiteSoft),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
