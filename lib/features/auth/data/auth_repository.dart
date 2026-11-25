import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/store_info.dart';
import '../../../core/utils/json.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

class LoginResult {
  const LoginResult({required this.storeKey, required this.store});

  final String storeKey;
  final StoreInfo? store;

  factory LoginResult.fromJson(Object? data) {
    final map = asMap(data);
    final key = asString(map?['store_key']);
    if (key == null || key.isEmpty) {
      throw const ApiException(
        ApiErrorKind.badResponse,
        'Sign in failed. Please try again.',
      );
    }
    final store = asMap(map?['store']);
    return LoginResult(
      storeKey: key,
      store: store == null ? null : StoreInfo.fromJson(store),
    );
  }
}

/// `POST /login` and `POST /logout`.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// [login] is a phone number or email; [pin] is the App PIN.
  /// Throws [ApiException] (401 = wrong phone/email or PIN).
  Future<LoginResult> login({
    required String login,
    required String pin,
  }) async {
    final res = await _api.post(
      '/login',
      body: {'login': login, 'pin': pin},
      parse: LoginResult.fromJson,
    );
    return res.data;
  }

  /// Nothing has to happen on the server; failures are ignored.
  Future<void> logout() async {
    try {
      await _api.post('/logout', parse: (_) => null);
    } catch (_) {
      // Logging out must always work, even offline.
    }
  }
}
