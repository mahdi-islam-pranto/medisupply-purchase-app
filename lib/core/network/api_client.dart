import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../session/session_controller.dart';
import '../utils/json.dart';
import 'api_exception.dart';
import 'store_key_interceptor.dart';

/// The `{ status, message, data }` envelope every endpoint returns.
class ApiResponse<T> {
  const ApiResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  final int status;
  final String message;
  final T data;
}

typedef DataParser<T> = T Function(Object? data);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    StoreKeyInterceptor(
      readKey: () => ref.read(sessionProvider).storeKey,
      onUnauthorized: () =>
          ref.read(sessionProvider.notifier).signOut(expired: true),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false, // keeps the store_key out of the logs
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
  }
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    ref.watch(dioProvider),
    readKey: () => ref.read(sessionProvider).storeKey,
  ),
);

/// Thin wrapper over Dio: sends the request, unwraps the envelope,
/// and throws [ApiException] for every kind of failure.
class ApiClient {
  ApiClient(this._dio, {required this._readKey});

  final Dio _dio;
  final String? Function() _readKey;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required DataParser<T> parse,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.get<Object?>(
      path,
      queryParameters: _clean(query),
      cancelToken: cancelToken,
    ),
    parse,
  );

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    required DataParser<T> parse,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.post<Object?>(path, data: body, cancelToken: cancelToken),
    parse,
  );

  /// Full URL with `store_key` as a parameter, for PDFs that the phone's
  /// browser / PDF viewer opens directly (it can't send our header).
  Uri authedUrl(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse('${ApiConfig.baseUrl}$path');
    final params = <String, String>{
      ...?_clean(query)?.map((k, v) => MapEntry(k, v.toString())),
      ApiConfig.storeKeyParam: _readKey() ?? '',
    };
    return base.replace(queryParameters: params);
  }

  Future<ApiResponse<T>> _send<T>(
    Future<Response<Object?>> Function() call,
    DataParser<T> parse,
  ) async {
    final Response<Object?> res;
    try {
      res = await call();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }

    final body = asMap(res.data);
    if (body == null) {
      throw const ApiException(
        ApiErrorKind.badResponse,
        'Unexpected reply from the server. Please try again.',
      );
    }

    final status = asInt(body['status']) ?? res.statusCode ?? 200;
    if (status >= 400) {
      throw ApiException.fromResponse(status, body);
    }

    try {
      return ApiResponse(
        status: status,
        message: asString(body['message']) ?? '',
        data: parse(body['data']),
      );
    } on ApiException {
      rethrow;
    } catch (e, st) {
      debugPrint('Parse error on ${res.requestOptions.path}: $e\n$st');
      throw const ApiException(
        ApiErrorKind.badResponse,
        'Could not read the server reply. Please try again.',
      );
    }
  }

  /// Drops null / empty values so we don't send `?q=` or `date=null`.
  static Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    return Map.fromEntries(
      query.entries.where((e) => e.value != null && e.value != ''),
    );
  }
}
