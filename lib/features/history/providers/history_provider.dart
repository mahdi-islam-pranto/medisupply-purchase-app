import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_list.dart';
import '../../../core/models/quote_summary.dart';
import '../../../core/session/session_controller.dart';
import '../data/history_repository.dart';

final historyProvider =
    AsyncNotifierProvider<HistoryController, PagedList<QuoteSummary>>(
      HistoryController.new,
    );

/// Quote history with "load more" as the user scrolls.
class HistoryController extends AsyncNotifier<PagedList<QuoteSummary>> {
  @override
  Future<PagedList<QuoteSummary>> build() {
    ref.watch(sessionProvider.select((s) => s.storeKey));
    return ref.read(historyRepositoryProvider).page(1);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        state.isLoading ||
        current.loadingMore ||
        !current.hasMore) {
      return;
    }
    final loading = current.copyWith(loadingMore: true, clearError: true);
    state = AsyncData(loading);
    try {
      final next = await ref
          .read(historyRepositoryProvider)
          .page(current.page + 1);
      // Ignore if the list was refreshed meanwhile.
      if (!ref.mounted || !identical(state.value, loading)) return;
      state = AsyncData(
        loading.copyWith(
          items: [...current.items, ...next.items],
          page: next.page,
          lastPage: next.lastPage,
          loadingMore: false,
        ),
      );
    } catch (e) {
      if (!ref.mounted || !identical(state.value, loading)) return;
      state = AsyncData(loading.copyWith(loadingMore: false, loadMoreError: e));
    }
  }
}
