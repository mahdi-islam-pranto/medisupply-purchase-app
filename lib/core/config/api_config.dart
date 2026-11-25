/// Server settings for the Store Quote API.
abstract final class ApiConfig {
  static const String baseUrl =
      'https://medisupplybd.softwhile.com/api/store-app';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Header that carries the saved `store_key` on every call.
  static const String storeKeyHeader = 'X-Store-Key';

  /// Query parameter version of the key, used for PDF links
  /// that are opened outside the app.
  static const String storeKeyParam = 'store_key';

  /// Calls that must never trigger "session ended" handling.
  static const Set<String> publicPaths = {'/login', '/logout'};
}
