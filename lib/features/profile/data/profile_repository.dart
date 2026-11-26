import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'profile_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  /// `GET /profile` — store info, quote window and notifications.
  Future<ProfileData> fetch() async {
    final res = await _api.get('/profile', parse: ProfileData.fromJson);
    return res.data;
  }

  /// `POST /change-pin`. Returns the server message ("PIN changed").
  /// Throws an `ApiException` with field errors on 422.
  Future<String> changePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) async {
    final res = await _api.post(
      '/change-pin',
      body: {
        'current_pin': currentPin,
        'new_pin': newPin,
        'new_pin_confirmation': confirmPin,
      },
      parse: (_) => null,
    );
    return res.message.isEmpty ? 'PIN changed' : res.message;
  }
}
