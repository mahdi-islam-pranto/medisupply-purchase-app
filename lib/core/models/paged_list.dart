/// A list that loads page by page (History, approved date range).
class PagedList<T> {
  const PagedList({
    required this.items,
    required this.page,
    required this.lastPage,
    this.total,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<T> items;
  final int page;
  final int lastPage;
  final int? total;
  final bool loadingMore;

  /// Error from the last "load more"; the list stays on screen.
  final Object? loadMoreError;

  bool get hasMore => page < lastPage;

  PagedList<T> copyWith({
    List<T>? items,
    int? page,
    int? lastPage,
    bool? loadingMore,
    Object? loadMoreError,
    bool clearError = false,
  }) => PagedList(
    items: items ?? this.items,
    page: page ?? this.page,
    lastPage: lastPage ?? this.lastPage,
    total: total,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: clearError ? null : (loadMoreError ?? this.loadMoreError),
  );
}
