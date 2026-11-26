import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_list.dart';
import '../../../core/session/session_controller.dart';
import '../data/approved_models.dart';
import '../data/approved_repository.dart';

/// One day of approved quotes. `null` date = latest day with approvals.
final approvedDayProvider = FutureProvider.autoDispose
    .family<ApprovedDay?, String?>((ref, date) {
      ref.watch(sessionProvider.select((s) => s.storeKey));
      return ref.read(approvedRepositoryProvider).day(date);
    });

/// A From–To range (dates only).
typedef DayRange = ({DateTime from, DateTime to});

class ApprovedRangeState {
  const ApprovedRangeState({
    required this.rangeLabel,
    required this.dayCount,
    required this.approvedLines,
    required this.amount,
    required this.days,
  });

  final String rangeLabel;
  final int dayCount;
  final int approvedLines;
  final num amount;
  final PagedList<ApprovedDay> days;

  ApprovedRangeState withDays(PagedList<ApprovedDay> days) =>
      ApprovedRangeState(
        rangeLabel: rangeLabel,
        dayCount: dayCount,
        approvedLines: approvedLines,
        amount: amount,
        days: days,
      );
}

final approvedRangeProvider = AsyncNotifierProvider.autoDispose
    .family<ApprovedRangeController, ApprovedRangeState, DayRange>(
      ApprovedRangeController.new,
    );

/// Approved days in a range, paged.
class ApprovedRangeController extends AsyncNotifier<ApprovedRangeState> {
  ApprovedRangeController(this.range);

  final DayRange range;

  ApprovedRepository get _repo => ref.read(approvedRepositoryProvider);

  @override
  Future<ApprovedRangeState> build() async {
    ref.watch(sessionProvider.select((s) => s.storeKey));
    final first = await _repo.range(from: range.from, to: range.to);
    return ApprovedRangeState(
      rangeLabel: first.rangeLabel,
      dayCount: first.dayCount,
      approvedLines: first.approvedLines,
      amount: first.amount,
      days: PagedList(
        items: first.days,
        page: first.page,
        lastPage: first.lastPage,
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        state.isLoading ||
        current.days.loadingMore ||
        !current.days.hasMore) {
      return;
    }
    final loading = current.withDays(
      current.days.copyWith(loadingMore: true, clearError: true),
    );
    state = AsyncData(loading);
    try {
      final next = await _repo.range(
        from: range.from,
        to: range.to,
        page: current.days.page + 1,
      );
      if (!ref.mounted || !identical(state.value, loading)) return;
      state = AsyncData(
        loading.withDays(
          loading.days.copyWith(
            items: [...current.days.items, ...next.days],
            page: next.page,
            lastPage: next.lastPage,
            loadingMore: false,
          ),
        ),
      );
    } catch (e) {
      if (!ref.mounted || !identical(state.value, loading)) return;
      state = AsyncData(
        loading.withDays(
          loading.days.copyWith(loadingMore: false, loadMoreError: e),
        ),
      );
    }
  }
}
