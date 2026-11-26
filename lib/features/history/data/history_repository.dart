import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paged_list.dart';
import '../../../core/models/quote_summary.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.watch(apiClientProvider)),
);

class HistoryRepository {
  HistoryRepository(this._api);

  final ApiClient _api;

  /// `GET /history` — one page, newest day first.
  Future<PagedList<QuoteSummary>> page(int page, {int perPage = 20}) async {
    final res = await _api.get(
      '/history',
      query: {'page': page, 'per_page': perPage},
      parse: (data) {
        final map = asMap(data) ?? const {};
        return PagedList(
          items: asMapList(map['items']).map(QuoteSummary.fromJson).toList(),
          page: asInt(map['page']) ?? page,
          lastPage: asInt(map['last_page']) ?? page,
          total: asInt(map['total']),
        );
      },
    );
    return res.data;
  }
}
