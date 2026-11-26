import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'report_models.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(apiClientProvider)),
);

class ReportsRepository {
  ReportsRepository(this._api);

  final ApiClient _api;

  /// `GET /reports?period=`.
  Future<ReportData> report(ReportPeriod period) async {
    final res = await _api.get(
      '/reports',
      query: {'period': period.apiValue},
      parse: (data) => ReportData.fromJson(data, requested: period),
    );
    return res.data;
  }
}
