import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/pdf_launcher.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/load_more_footer.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/approved_models.dart';
import '../data/approved_repository.dart';
import '../providers/approved_providers.dart';
import 'widgets/approved_items.dart';

/// Approved quotes in a From–To range (`GET /approved/list`).
class ApprovedRangeScreen extends ConsumerStatefulWidget {
  const ApprovedRangeScreen({super.key});

  @override
  ConsumerState<ApprovedRangeScreen> createState() =>
      _ApprovedRangeScreenState();
}

class _ApprovedRangeScreenState extends ConsumerState<ApprovedRangeScreen> {
  static const _presets = [7, 30, 90];

  late DayRange _range = _lastDays(30);

  static DateTime get _today => DateUtils.dateOnly(DateTime.now());

  static DayRange _lastDays(int days) =>
      (from: _today.subtract(Duration(days: days - 1)), to: _today);

  int? get _activePreset {
    for (final d in _presets) {
      final r = _lastDays(d);
      if (r.from == _range.from && r.to == _range.to) return d;
    }
    return null;
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: _today,
      initialDateRange: DateTimeRange(start: _range.from, end: _range.to),
      helpText: 'Approved quotes from – to',
      saveText: 'Show',
    );
    if (picked != null) {
      setState(
        () => _range = (
          from: DateUtils.dateOnly(picked.start),
          to: DateUtils.dateOnly(picked.end),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = approvedRangeProvider(_range);
    final async = ref.watch(provider);
    final theme = Theme.of(context).textTheme;

    final rangeText =
        '${Fmt.dayMonthYear(_range.from)} – ${Fmt.dayMonthYear(_range.to)}';

    final controls = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            onTap: _pickRange,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(rangeText, style: theme.titleMedium)),
                const Icon(
                  Icons.edit_calendar_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final d in _presets)
                ChoiceChip(
                  label: Text('Last $d days'),
                  selected: _activePreset == d,
                  showCheckmark: false,
                  selectedColor: AppColors.primaryLight,
                  labelStyle: theme.labelMedium?.copyWith(
                    color: _activePreset == d
                        ? AppColors.primaryDark
                        : AppColors.textMuted,
                  ),
                  side: const BorderSide(color: AppColors.border),
                  backgroundColor: AppColors.surface,
                  onSelected: (_) => setState(() => _range = _lastDays(d)),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );

    Widget list;
    if (async.hasValue) {
      final s = async.requireValue;
      final days = s.days;
      list = RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(provider);
          try {
            await ref.read(provider.future);
          } catch (_) {}
        },
        child: LoadMoreListener(
          onLoadMore: () => ref.read(provider.notifier).loadMore(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: days.items.isEmpty ? 3 : days.items.length + 3,
            separatorBuilder: (_, i) =>
                i < 2 ? const SizedBox.shrink() : const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == 0) return controls;
              if (i == 1) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _SummaryCard(state: s),
                );
              }
              if (days.items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: EmptyView(
                    icon: Icons.fact_check_outlined,
                    title: 'No approved quotes',
                    message: 'Try a longer date range.',
                  ),
                );
              }
              if (i == days.items.length + 2) {
                return LoadMoreFooter(
                  list: days,
                  onRetry: () => ref.read(provider.notifier).loadMore(),
                );
              }
              final day = days.items[i - 2];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DayCard(
                  day: day,
                  onPdf: () => openPdf(
                    context,
                    ref.read(approvedRepositoryProvider).pdfUrl(day.date),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      list = ListView(
        children: [
          controls,
          const SizedBox(height: 40),
          if (async.hasError)
            ErrorView(
              error: async.error!,
              onRetry: () => ref.invalidate(provider),
            )
          else
            const LoadingView(),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(
            title: 'Approved by date',
            subtitle: 'Approved quotes',
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
          ),
          Expanded(child: list),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});
  final ApprovedRangeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    Widget stat(String label, String value, {Color? color}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.bodySmall?.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: theme.titleLarge?.copyWith(color: color)),
          ),
        ],
      ),
    );

    return AppCard(
      color: AppColors.primaryLight,
      borderColor: null,
      child: Row(
        children: [
          stat('Days', '${state.dayCount}'),
          stat('Approved lines', '${state.approvedLines}'),
          stat('Amount', Fmt.money(state.amount), color: AppColors.primaryDark),
        ],
      ),
    );
  }
}

/// One approved day; tap to show its products.
class _DayCard extends StatefulWidget {
  const _DayCard({required this.day, required this.onPdf});
  final ApprovedDay day;
  final VoidCallback onPdf;

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final day = widget.day;
    final date = day.parsedDate;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: day.items.isEmpty
                ? null
                : () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date != null ? Fmt.dayMonthYear(date) : day.dateLabel,
                          style: theme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StatusBadge(
                              label: day.approvedText,
                              tone: BadgeTone.success,
                              compact: true,
                            ),
                            const SizedBox(width: 8),
                            Text(Fmt.money(day.total), style: theme.labelLarge),
                          ],
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onPdf,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('PDF'),
                  ),
                  if (day.items.isNotEmpty)
                    Icon(
                      _open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(),
                        ApprovedItemsList(items: day.items, total: day.total),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
