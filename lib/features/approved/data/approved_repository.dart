import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';
import 'approved_models.dart';

final approvedRepositoryProvider = Provider<ApprovedRepository>(
  (ref) => ApprovedRepository(ref.watch(apiClientProvider)),
);

class ApprovedRepository {
  ApprovedRepository(this._api);

  final ApiClient _api;

  /// One day. `date == null` → latest day with an approved line.
  /// Returns `null` when the store has no approved quotes at all.
  Future<ApprovedDay?> day(String? date) async {
    final res = await _api.get(
      '/approved',
      query: {'date': date},
      parse: (data) {
        final map = asMap(data);
        return map == null ? null : ApprovedDay.fromJson(map);
      },
    );
    return res.data;
  }

  Future<ApprovedRangePage> range({
    required DateTime from,
    required DateTime to,
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _api.get(
      '/approved/list',
      query: {
        'from': Fmt.apiDate(from),
        'to': Fmt.apiDate(to),
        'items': 1,
        'page': page,
        'per_page': perPage,
      },
      parse: ApprovedRangePage.fromJson,
    );
    return res.data;
  }

  /// PDF of one day's approved quotes (opened outside the app).
  Uri pdfUrl(String date) => _api.authedUrl('/approved/pdf', {'date': date});
}
