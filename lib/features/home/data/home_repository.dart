import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'home_data.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(ref.watch(apiClientProvider)),
);

class HomeRepository {
  HomeRepository(this._api);

  final ApiClient _api;

  Future<HomeData> fetch() async {
    final res = await _api.get('/home', parse: HomeData.fromJson);
    return res.data;
  }
}
