import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/countdown.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/quote_models.dart';

/// Screen 4 — quoting is closed: lock card + "Today's quotes".
class QuoteClosedView extends StatelessWidget {
  const QuoteClosedView({
    super.key,
    required this.data,
    required this.onRefresh,
    required this.onWindowChanged,
  });

  final QuoteData data;
  final Future<void> Function() onRefresh;
  final VoidCallback onWindowChanged;

  /// "today" if the next opening is on the same date as the list, else "tomorrow".
  String get _nextDay {
    final next = data.window.nextChange;
    if (next != null && data.date.isNotEmpty && next.startsWith(data.date)) {
      return 'today';
    }
    return 'tomorrow';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final w = data.window;
    final today = data.todaysQuote;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const ScreenHeader(title: 'Products to quote'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCard(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: AppColors.neutralBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.textMuted,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Quoting is closed',
                                style: theme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your window is ${w.range} daily. Next window '
                                'opens $_nextDay at ${w.opensAt}.',
                                textAlign: TextAlign.center,
                                style: theme.bodyLarge?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Countdown(
                                deadline: w.deadline,
                                onDone: onWindowChanged,
                                builder: (context, s) => s == 0
                                    ? const SizedBox.shrink()
                                    : Text(
                                        'Opens in ${Fmt.countdown(s)}',
                                        style: theme.labelLarge?.copyWith(
                                          color: AppColors.primary,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _TodaysQuoteCard(today: today),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _BottomBar(
            child: PrimaryButton(label: 'Send quotes', onPressed: null),
          ),
        ],
      ),
    );
  }
}

class _TodaysQuoteCard extends StatelessWidget {
  const _TodaysQuoteCard({required this.today});
  final TodaysQuote? today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final t = today;

    final String text;
    Widget? badge;
    if (t == null || t.items == 0) {
      text = 'No quotes were sent today.';
    } else {
      final products = '${t.items} ${t.items == 1 ? 'product' : 'products'}';
      final at = t.sentAt != null ? ' at ${t.sentAt}' : '';
      text = t.status == 'pending'
          ? '$products sent$at. Approved items appear here once reviewed.'
          : '$products sent$at.';
      badge = t.status == 'pending'
          ? const StatusBadge(
              label: 'Awaiting approval',
              tone: BadgeTone.warning,
            )
          : StatusBadge.forStatus(
              t.status,
              label: t.statusLabel.isEmpty ? null : t.statusLabel,
            );
    }

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Today’s quotes', style: theme.titleMedium)),
              ?badge,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          if (t?.note != null && t!.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Note: ${t.note}', style: theme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// White strip pinned above the bottom navigation.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: const BoxDecoration(
      color: AppColors.background,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: child,
  );
}
