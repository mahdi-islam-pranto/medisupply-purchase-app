import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/countdown.dart';
import '../../../../core/widgets/window_chip.dart';
import '../../data/home_data.dart';

/// The big green card at the top of Home:
/// window status, products to quote, countdown and "Quote now".
class WindowHeroCard extends StatelessWidget {
  const WindowHeroCard({
    super.key,
    required this.data,
    required this.onQuoteNow,
    required this.onWindowChanged,
  });

  final HomeData data;
  final VoidCallback onQuoteNow;
  final VoidCallback onWindowChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final window = data.window;
    final open = window.open;

    final String headline;
    if (!open) {
      headline = 'Quoting is closed';
    } else if (data.productsToQuote == 0) {
      headline = 'No products to quote';
    } else {
      headline =
          '${data.productsToQuote} '
          '${data.productsToQuote == 1 ? 'product' : 'products'} to quote';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: open ? AppColors.primary : AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppTheme.radius + 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WindowChip(label: window.label, open: open),
          const SizedBox(height: 14),
          Text(
            headline,
            style: theme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Countdown(
            deadline: window.deadline,
            onDone: onWindowChanged,
            builder: (context, secondsLeft) => Text(
              _subline(open, secondsLeft),
              style: theme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: data.canQuote ? onQuoteNow : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.25),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
              ),
              child: Text(open ? 'Quote now' : 'Opens at ${window.opensAt}'),
            ),
          ),
        ],
      ),
    );
  }

  String _subline(bool open, int secondsLeft) {
    final time = Fmt.countdown(secondsLeft);
    if (open) {
      return '${data.priced} priced · $time left';
    }
    return secondsLeft > 0
        ? 'Opens in $time'
        : 'Your window is ${data.window.range} daily';
  }
}
