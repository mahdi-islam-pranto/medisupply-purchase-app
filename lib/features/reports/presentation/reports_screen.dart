import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/gallery_saver.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/money_tile.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/state_views.dart';
import '../data/report_models.dart';
import '../providers/reports_providers.dart';
import 'widgets/period_selector.dart';
import 'widgets/report_table.dart';

/// Screen 7 — Sales & collection.
/// "Download Report" saves the report (as shown) to the Gallery as an image.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  /// Wraps the report sheet that gets saved as an image.
  final _sheetKey = GlobalKey();
  bool _saving = false;

  Future<void> _refresh(ReportPeriod period) async {
    ref.invalidate(reportProvider(period));
    try {
      await ref.read(reportProvider(period).future);
    } catch (_) {
      // Shown by the listener / error view.
    }
  }

  Future<void> _downloadReport(ReportData data) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Let the "Generated …" time update before capturing.
      await WidgetsBinding.instance.endOfFrame;
      final png = await captureToPng(_sheetKey);
      await saveToGallery(
        png,
        name:
            'MediPurchase_Report_${data.period.apiValue}_'
            '${Fmt.apiDate(DateTime.now())}',
      );
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Report saved to Gallery ($galleryAlbum album)',
        actionLabel: 'View',
        onAction: openGallery,
      );
    } on GallerySaveException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Could not save the report. Please try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(reportPeriodProvider);
    final async = ref.watch(reportProvider(period));
    final storeName = ref.watch(sessionProvider.select((s) => s.store?.name));

    // A failed pull-to-refresh keeps the old numbers and shows a snackbar.
    ref.listen(reportProvider(period), (prev, next) {
      if (next.hasError && next.hasValue && !next.isLoading) {
        showAppSnackBar(context, errorMessage(next.error!), error: true);
      }
    });

    final data = async.value;

    final Widget content;
    if (data != null) {
      // A fully laid-out scroll view (not a lazy ListView) so the saved
      // image includes every row, even those scrolled off screen.
      content = RefreshIndicator(
        onRefresh: () => _refresh(period),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: RepaintBoundary(
            key: _sheetKey,
            child: _ReportSheet(data: data, storeName: storeName),
          ),
        ),
      );
    } else if (async.hasError) {
      content = ErrorView(
        error: async.error!,
        onRetry: () => ref.invalidate(reportProvider(period)),
      );
    } else {
      content = const SkeletonList(blocks: [72, 84, 20, 260]);
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'Sales & collection'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: PeriodSelector(
              selected: period,
              onChanged: _saving
                  ? (_) {}
                  : ref.read(reportPeriodProvider.notifier).select,
            ),
          ),
          Expanded(child: content),
          if (data != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: PrimaryButton(
                label: 'Download Report',
                icon: Icons.download_rounded,
                loading: _saving,
                onPressed: () => _downloadReport(data),
              ),
            ),
        ],
      ),
    );
  }
}

/// The report as shown on screen and saved to the Gallery.
class _ReportSheet extends StatelessWidget {
  const _ReportSheet({required this.data, required this.storeName});

  final ReportData data;
  final String? storeName;

  static final _generatedFmt = DateFormat('d MMM yyyy, h:mm a', 'en_US');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final muted = theme.bodyMedium?.copyWith(color: AppColors.textMuted);

    // Solid background so the saved PNG is not transparent.
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Who / what / when — so the image makes sense on its own.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (storeName != null && storeName!.isNotEmpty)
                        Text(storeName!, style: muted),
                      const SizedBox(height: 2),
                      Text(
                        '${data.period.label} report',
                        style: theme.titleLarge,
                      ),
                      if (data.rangeLabel != null &&
                          data.rangeLabel!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(data.rangeLabel!, style: muted),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const AppLogo(size: 52),
              ],
            ),
            const SizedBox(height: 16),
            MoneySummaryRow(
              sales: data.summary.sales,
              received: data.summary.received,
              due: data.summary.due,
            ),
            const SizedBox(height: 20),
            Text(_tableTitle(data.period), style: theme.titleMedium),
            const SizedBox(height: 10),
            ReportTable(period: data.period, rows: data.rows),
            const SizedBox(height: 12),
            Text(
              'Generated ${_generatedFmt.format(DateTime.now())}',
              textAlign: TextAlign.center,
              style: theme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  static String _tableTitle(ReportPeriod p) => switch (p) {
    ReportPeriod.daily => 'Day by day',
    ReportPeriod.weekly => 'Week by week',
    ReportPeriod.monthly => 'Month by month',
  };
}
