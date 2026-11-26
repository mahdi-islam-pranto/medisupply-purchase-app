import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/gallery_saver.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../router/routes.dart';
import '../data/approved_models.dart';
import '../providers/approved_providers.dart';
import 'widgets/approved_items.dart';

/// Screen 5 — Approved quotes for one day.
/// "Download Orders" saves the order (as shown) to the Gallery as an image.
class ApprovedDayScreen extends ConsumerStatefulWidget {
  const ApprovedDayScreen({super.key, this.date});

  /// `Y-m-d`; `null` = latest day with an approved line.
  final String? date;

  @override
  ConsumerState<ApprovedDayScreen> createState() => _ApprovedDayScreenState();
}

class _ApprovedDayScreenState extends ConsumerState<ApprovedDayScreen> {
  /// Wraps the order sheet that gets saved as an image.
  final _sheetKey = GlobalKey();
  bool _saving = false;

  Future<void> _pickDate(ApprovedDay? current) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initial = current?.parsedDate ?? Fmt.parseDate(widget.date) ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: 'Show approved quotes for',
    );
    if (picked != null && mounted) {
      context.replace(Routes.approvedFor(Fmt.apiDate(picked)));
    }
  }

  Future<void> _downloadOrders(ApprovedDay day) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final png = await captureToPng(_sheetKey);
      await saveToGallery(png, name: 'MediPurchase_Order_${day.date}');
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Order saved to Gallery ($galleryAlbum album)',
        actionLabel: 'View',
        onAction: openGallery,
      );
    } on GallerySaveException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Could not save the order. Please try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(approvedDayProvider(widget.date));
    try {
      await ref.read(approvedDayProvider(widget.date).future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(approvedDayProvider(widget.date));
    final storeName = ref.watch(sessionProvider.select((s) => s.store?.name));
    final day = async.value;
    final hasOrder = day != null && day.items.isNotEmpty;

    Widget body;
    if (hasOrder) {
      // Header + order card live inside the captured area, so the saved
      // image shows the store, date and every line — even off screen.
      body = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: RepaintBoundary(
          key: _sheetKey,
          child: _OrderSheet(day: day, storeName: storeName),
        ),
      );
    } else {
      final Widget content;
      if (async.hasValue) {
        content = _Empty(day: day, onPickDate: () => _pickDate(day));
      } else if (async.hasError) {
        content = ErrorView(
          error: async.error!,
          onRetry: () => ref.invalidate(approvedDayProvider(widget.date)),
        );
      } else {
        content = const LoadingView();
      }
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Approved quotes',
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Pick a date',
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => _pickDate(day),
          ),
          IconButton(
            tooltip: 'Date range',
            icon: const Icon(Icons.date_range_rounded),
            onPressed: () => context.go(Routes.approvedRange),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: RefreshIndicator(onRefresh: _refresh, child: body),
          ),
          if (hasOrder)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: PrimaryButton(
                  label: 'Download Orders',
                  icon: Icons.download_rounded,
                  loading: _saving,
                  onPressed: () => _downloadOrders(day),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The order as shown on screen and saved to the Gallery.
class _OrderSheet extends StatelessWidget {
  const _OrderSheet({required this.day, required this.storeName});

  final ApprovedDay day;
  final String? storeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final refs = [
      if (day.quoteNo != null) 'Quote ${day.quoteNo}',
      if (day.billNo != null) 'Bill ${day.billNo}',
    ];

    final notes = [
      if (day.notApprovedCount > 0)
        '${day.notApprovedCount} '
            '${day.notApprovedCount == 1 ? 'quote was' : 'quotes were'} '
            'not approved.',
      if (day.pendingCount > 0) '${day.pendingCount} still waiting for review.',
    ];

    // Solid background so the saved PNG is not transparent.
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Approved quotes',
              subtitle: [
                storeName,
                day.dateLabel,
              ].where((s) => s != null && s.isNotEmpty).join(' · '),
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 16),
              trailing: const AppLogo(size: 52),
            ),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      StatusBadge(
                        label: day.approvedText,
                        tone: BadgeTone.success,
                      ),
                      const Spacer(),
                      if (refs.isNotEmpty)
                        Flexible(
                          child: Text(
                            refs.join(' · '),
                            textAlign: TextAlign.right,
                            style: theme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ApprovedItemsList(items: day.items, total: day.total),
                ],
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  notes.join(' '),
                  style: theme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.day, required this.onPickDate});
  final ApprovedDay? day;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final pending = day?.pendingCount ?? 0;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 40),
        EmptyView(
          icon: Icons.fact_check_outlined,
          title: day == null
              ? 'No approved quotes yet'
              : 'Nothing approved on this day',
          message: pending > 0
              ? '$pending ${pending == 1 ? 'quote is' : 'quotes are'} still '
                    'waiting for review.'
              : 'Approved items appear here once MediSupply reviews your quotes.',
          action: TextButton.icon(
            onPressed: onPickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: const Text('Pick another date'),
          ),
        ),
      ],
    );
  }
}
