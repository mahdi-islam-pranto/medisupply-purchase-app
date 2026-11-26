import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/quote_summary.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/pdf_launcher.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/load_more_footer.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../router/routes.dart';
import '../../approved/data/approved_repository.dart';
import '../providers/history_provider.dart';

/// Screen 6 — Quote history.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(historyProvider);
    try {
      await ref.read(historyProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(historyProvider);
    final storeName = ref.watch(sessionProvider.select((s) => s.store?.name));

    ref.listen(historyProvider, (prev, next) {
      if (next.hasError && next.hasValue && !next.isLoading) {
        showAppSnackBar(context, errorMessage(next.error!), error: true);
      }
    });

    final header = ScreenHeader(
      title: 'Quote history',
      subtitle: storeName,
      trailing: TextButton.icon(
        onPressed: () => context.go(Routes.approvedRange),
        icon: const Icon(Icons.date_range_rounded, size: 20),
        label: const Text('By date'),
      ),
    );

    Widget body;
    if (async.hasValue) {
      final list = async.requireValue;
      body = RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: LoadMoreListener(
          onLoadMore: () => ref.read(historyProvider.notifier).loadMore(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: list.items.isEmpty ? 2 : list.items.length + 2,
            separatorBuilder: (_, i) =>
                i == 0 ? const SizedBox.shrink() : const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == 0) return header;
              if (list.items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: EmptyView(
                    icon: Icons.history_rounded,
                    title: 'No quotes yet',
                    message: 'Days you send quotes will show up here.',
                  ),
                );
              }
              if (i == list.items.length + 1) {
                return LoadMoreFooter(
                  list: list,
                  onRetry: () => ref.read(historyProvider.notifier).loadMore(),
                );
              }
              final q = list.items[i - 1];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HistoryCard(
                  quote: q,
                  onTap: () => context.go(Routes.approvedFor(q.date)),
                  onPdf: () => openPdf(
                    context,
                    ref.read(approvedRepositoryProvider).pdfUrl(q.date),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: async.hasError
                ? ErrorView(
                    error: async.error!,
                    onRetry: () => ref.invalidate(historyProvider),
                  )
                : const SkeletonList(blocks: SkeletonList.cards),
          ),
        ],
      );
    }

    return SafeArea(bottom: false, child: body);
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.quote,
    required this.onTap,
    required this.onPdf,
  });

  final QuoteSummary quote;
  final VoidCallback onTap;
  final VoidCallback onPdf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final date = quote.parsedDate;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date != null ? Fmt.dayMonthYear(date) : quote.dateLabel,
                  style: theme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${quote.approvedText} · ${quote.amountText}',
                  style: theme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: StatusBadge.forStatus(
                  quote.status,
                  label: quote.statusLabel.isEmpty ? null : quote.statusLabel,
                ),
              ),
              TextButton.icon(
                onPressed: onPdf,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
