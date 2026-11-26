import 'package:flutter/material.dart';

import '../models/paged_list.dart';
import '../network/api_exception.dart';
import '../theme/app_colors.dart';

/// Bottom of a paged list: spinner while loading, retry on error,
/// nothing when all pages are loaded.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({super.key, required this.list, required this.onRetry});

  final PagedList<Object?> list;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (list.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (list.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              errorMessage(list.loadMoreError!),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.negative),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}

/// Calls [onLoadMore] when the user scrolls near the end of [child].
class LoadMoreListener extends StatelessWidget {
  const LoadMoreListener({
    super.key,
    required this.onLoadMore,
    required this.child,
  });

  final VoidCallback onLoadMore;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 400) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}
