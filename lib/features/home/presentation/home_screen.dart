import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/money_tile.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/state_views.dart';
import '../../../router/routes.dart';
import '../../quote/providers/quote_providers.dart';
import '../data/home_data.dart';
import '../providers/home_provider.dart';
import 'widgets/home_cards.dart';
import 'widgets/window_hero_card.dart';

/// Screen 2 — Home.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    try {
      ref.invalidate(homeProvider);
      await ref.read(homeProvider.future);
    } catch (_) {
      // Shown by the listener below / the error view.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeProvider);

    // A failed pull-to-refresh keeps the old data and shows a snackbar.
    ref.listen(homeProvider, (prev, next) {
      if (next.hasError && next.hasValue && !next.isLoading) {
        showAppSnackBar(context, errorMessage(next.error!), error: true);
      }
    });

    final Widget body;
    if (async.hasValue) {
      body = _HomeContent(
        data: async.requireValue,
        onRefresh: () => _refresh(ref),
      );
    } else if (async.hasError) {
      body = _HomeShell(
        child: ErrorView(
          error: async.error!,
          onRetry: () => ref.invalidate(homeProvider),
        ),
      );
    } else {
      body = const _HomeShell(child: SkeletonList(blocks: SkeletonList.home));
    }

    return SafeArea(bottom: false, child: body);
  }
}

/// Header + centered content, for loading and error states.
class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenHeader(title: 'Home'),
        Expanded(child: child),
      ],
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.data, required this.onRefresh});

  final HomeData data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const ScreenHeader(title: 'Home'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WindowHeroCard(
                  data: data,
                  onQuoteNow: () {
                    ref.invalidate(quoteProvider); // fresh list on arrival
                    context.go(Routes.quote);
                  },
                  // Window just opened/closed: reload to get the new state.
                  onWindowChanged: () => ref.invalidate(homeProvider),
                ),
                const SizedBox(height: 24),
                Text('Today', style: theme.titleMedium),
                const SizedBox(height: 10),
                MoneySummaryRow(
                  sales: data.today.sales,
                  received: data.today.received,
                  due: data.today.due,
                ),
                const SizedBox(height: 12),
                TotalDueCard(
                  totalDue: data.totalDue,
                  onViewReport: () => context.go(Routes.reports),
                ),
                if (data.lastQuote != null) ...[
                  const SizedBox(height: 12),
                  LastQuoteCard(
                    quote: data.lastQuote!,
                    onTap: () =>
                        context.go(Routes.approvedFor(data.lastQuote!.date)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
