import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/snackbars.dart';
import '../../../core/widgets/state_views.dart';
import '../../home/providers/home_provider.dart';
import '../data/quote_models.dart';
import '../data/quote_repository.dart';
import '../logic/quote_plan.dart';
import '../providers/quote_providers.dart';
import 'widgets/product_quote_card.dart';
import 'widgets/quote_closed_view.dart';
import 'widgets/quote_header.dart';

/// Screens 3 & 4 — Products to quote (open) / Quoting is closed.
class QuoteScreen extends ConsumerStatefulWidget {
  const QuoteScreen({super.key});

  @override
  ConsumerState<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends ConsumerState<QuoteScreen> {
  Future<void> _refresh() async {
    ref.invalidate(quoteProvider);
    try {
      await ref.read(quoteProvider.future);
    } catch (_) {
      // Shown by the error view / snackbar listener.
    }
  }

  /// The window just opened or closed: reload Quote and Home.
  void _onWindowChanged() {
    ref.invalidate(quoteProvider);
    ref.invalidate(homeProvider);
  }

  Future<void> _send() async {
    final plan = ref.read(quotePlanProvider);
    final form = ref.read(quoteFormProvider);
    final formCtrl = ref.read(quoteFormProvider.notifier);
    if (plan == null || form.sending) return;

    if (plan.incompleteIds.isNotEmpty) {
      formCtrl.showErrors();
      final n = plan.incompleteIds.length;
      showAppSnackBar(
        context,
        'Fill both Price and Qty for $n '
        '${n == 1 ? 'product' : 'products'}, or clear ${n == 1 ? 'it' : 'them'}.',
        error: true,
      );
      return;
    }
    if (!plan.canSend) return;

    FocusScope.of(context).unfocus();
    formCtrl.setSending(true);
    try {
      final result = await ref
          .read(quoteRepositoryProvider)
          .send(plan.items, note: plan.noteToSend);

      // Reload first, then drop the edits, so boxes never flash old values.
      ref.invalidate(homeProvider);
      await _refresh();
      formCtrl.clearEdits();

      if (!mounted) return;
      final no = result.quoteNo != null ? ' · ${result.quoteNo}' : '';
      showAppSnackBar(context, '${result.message}$no');
    } on ApiException catch (e) {
      formCtrl.setSending(false);
      if (e.kind == ApiErrorKind.locked) _onWindowChanged();
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } catch (e) {
      formCtrl.setSending(false);
      if (mounted) showAppSnackBar(context, errorMessage(e), error: true);
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave without sending?'),
        content: const Text('Prices you typed have not been sent yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(quoteProvider);
    final storeName = ref.watch(sessionProvider.select((s) => s.store?.name));

    ref.listen(quoteProvider, (prev, next) {
      // Failed refresh with data on screen → snackbar.
      if (next.hasError && next.hasValue && !next.isLoading) {
        showAppSnackBar(context, errorMessage(next.error!), error: true);
      }
      // Window closed while the user was typing.
      final wasOpen = prev?.value?.window.open ?? false;
      final nowOpen = next.value?.window.open ?? false;
      if (wasOpen && !nowOpen && next.hasValue) {
        final hadEdits = ref.read(quoteFormProvider).edits.isNotEmpty;
        ref.read(quoteFormProvider.notifier).clearEdits();
        if (hadEdits) {
          showAppSnackBar(
            context,
            'Quoting closed. Unsent prices were not sent.',
            error: true,
          );
        }
      }
    });

    if (async.hasValue) {
      final data = async.requireValue;
      if (!data.window.open) {
        return QuoteClosedView(
          data: data,
          storeName: storeName,
          onRefresh: _refresh,
          onWindowChanged: _onWindowChanged,
        );
      }
      return _OpenView(
        data: data,
        storeName: storeName,
        onRefresh: _refresh,
        onSend: _send,
        onWindowChanged: _onWindowChanged,
        onConfirmLeave: _confirmLeave,
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(title: 'Products to quote', subtitle: storeName),
          Expanded(
            child: async.hasError
                ? ErrorView(
                    error: async.error!,
                    onRetry: () => ref.invalidate(quoteProvider),
                  )
                : const SkeletonList(blocks: SkeletonList.cards),
          ),
        ],
      ),
    );
  }
}

/// Screen 3 — the window is open.
class _OpenView extends ConsumerWidget {
  const _OpenView({
    required this.data,
    required this.storeName,
    required this.onRefresh,
    required this.onSend,
    required this.onWindowChanged,
    required this.onConfirmLeave,
  });

  final QuoteData data;
  final String? storeName;
  final Future<void> Function() onRefresh;
  final VoidCallback onSend;
  final VoidCallback onWindowChanged;
  final VoidCallback onConfirmLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(quotePlanProvider);
    final form = ref.watch(quoteFormProvider);
    final formCtrl = ref.read(quoteFormProvider.notifier);
    if (plan == null) return const LoadingView();

    final query = form.search.trim().toLowerCase();
    final products = query.isEmpty
        ? data.products
        : data.products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(query) ||
                    (p.brand?.toLowerCase().contains(query) ?? false),
              )
              .toList();
    final showSearch = data.products.length > 5;

    return PopScope(
      canPop: !plan.hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onConfirmLeave();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuoteOpenHeader(
            data: data,
            storeName: storeName,
            onWindowChanged: onWindowChanged,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: data.products.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 60),
                        EmptyView(
                          icon: Icons.inventory_2_outlined,
                          title: 'No products to quote today',
                          message: 'Pull down to check again.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      // search box + products (+ "no match") + note
                      itemCount:
                          (showSearch ? 1 : 0) +
                          (products.isEmpty ? 1 : products.length) +
                          1,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        if (showSearch) {
                          if (i == 0) {
                            return _SearchBox(
                              initial: form.search,
                              onChanged: formCtrl.setSearch,
                            );
                          }
                          i -= 1;
                        }
                        if (products.isEmpty) {
                          if (i == 0) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: EmptyView(
                                icon: Icons.search_off_rounded,
                                title: 'No matching products',
                              ),
                            );
                          }
                        } else if (i < products.length) {
                          final p = products[i];
                          return ProductQuoteCard(
                            key: ValueKey(p.productId),
                            line: plan.lines[p.productId]!,
                            showErrors: form.showErrors,
                            onChanged: (price, qty) => formCtrl.setLine(
                              p.productId,
                              price: price,
                              qty: qty,
                            ),
                          );
                        }
                        return _NoteField(
                          initial: form.note ?? data.todaysQuote?.note ?? '',
                          onChanged: formCtrl.setNote,
                        );
                      },
                    ),
            ),
          ),
          _SendBar(plan: plan, sending: form.sending, onSend: onSend),
        ],
      ),
    );
  }
}

class _SendBar extends StatelessWidget {
  const _SendBar({
    required this.plan,
    required this.sending,
    required this.onSend,
  });

  final QuotePlan plan;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final incomplete = plan.incompleteIds.length;

    String? hint;
    Color hintColor = AppColors.textMuted;
    if (incomplete > 0) {
      hint =
          '$incomplete ${incomplete == 1 ? 'product needs' : 'products need'} '
          'both price and qty';
      hintColor = AppColors.negative;
    } else if (plan.hasChanges) {
      hint = 'You have changes that are not sent yet';
    }

    final allSent = !plan.hasChanges && plan.filledCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null) ...[
            Text(
              hint,
              textAlign: TextAlign.center,
              style: theme.bodySmall?.copyWith(color: hintColor),
            ),
            const SizedBox(height: 6),
          ],
          PrimaryButton(
            height: 48,
            label: allSent ? 'All quotes sent' : plan.buttonLabel,
            icon: allSent ? Icons.check_circle_outline_rounded : null,
            loading: sending,
            onPressed: plan.hasChanges ? onSend : null,
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatefulWidget {
  const _SearchBox({required this.initial, required this.onChanged});
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search products',
        prefixIcon: const Icon(Icons.search_rounded),
        isDense: true,
        suffixIcon: ListenableBuilder(
          listenable: _ctrl,
          builder: (context, _) => _ctrl.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _ctrl.clear();
                    widget.onChanged('');
                  },
                ),
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _NoteField extends StatefulWidget {
  const _NoteField({required this.initial, required this.onChanged});
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          'Note for MediSupply (optional)',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          minLines: 1,
          maxLines: 3,
          maxLength: 255,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. Delivery after 3 PM',
            counterText: '',
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
