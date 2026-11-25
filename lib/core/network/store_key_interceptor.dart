import 'package:dio/dio.dart';

import '../config/api_config.dart';

/// Adds `X-Store-Key` to every request, and signs the user out when
/// the server says the key is no longer valid (401).
class StoreKeyInterceptor extends Interceptor {
  StoreKeyInterceptor({required this.readKey, required this.onUnauthorized});

  final String? Function() readKey;
  final void Function() onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final key = readKey();
    if (key != null && key.isNotEmpty && !_isPublic(options.path)) {
      options.headers[ApiConfig.storeKeyHeader] = key;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // A 401 from /login just means "wrong PIN"; anywhere else it means
    // the store was made inactive or the key is invalid.
    if (err.response?.statusCode == 401 &&
        !_isPublic(err.requestOptions.path)) {
      onUnauthorized();
    }
    handler.next(err);
  }

  static bool _isPublic(String path) => ApiConfig.publicPaths.contains(path);
}
