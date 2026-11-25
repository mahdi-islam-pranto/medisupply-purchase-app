import 'package:dio/dio.dart';

import '../utils/json.dart';

enum ApiErrorKind {
  /// No internet / server unreachable.
  network,

  /// Server took too long.
  timeout,

  /// 401: wrong login, or store_key no longer valid.
  unauthorized,

  /// 422: input not valid. See [ApiException.fieldErrors].
  validation,

  /// 423: quoting window is closed.
  locked,

  /// 429: too many requests.
  rateLimited,

  /// 5xx or other unexpected HTTP status.
  server,

  /// Response was not the JSON shape we expect.
  badResponse,

  cancelled,
}

/// Every API failure is turned into this, so screens only handle one type.
class ApiException implements Exception {
  const ApiException(
    this.kind,
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  /// First validation message for [field], e.g. `fieldError('new_pin')`.
  String? fieldError(String field) {
    final list = fieldErrors[field];
    return (list == null || list.isEmpty) ? null : list.first;
  }

  bool get isUnauthorized => kind == ApiErrorKind.unauthorized;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          ApiErrorKind.timeout,
          'The server is taking too long. Please try again.',
        );
      case DioExceptionType.cancel:
        return const ApiException(ApiErrorKind.cancelled, 'Request cancelled.');
      case DioExceptionType.badResponse:
        final res = e.response;
        return ApiException.fromResponse(res?.statusCode ?? 0, res?.data);
      case DioExceptionType.badCertificate:
        return const ApiException(
          ApiErrorKind.network,
          'Secure connection failed. Check the phone date and time.',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          ApiErrorKind.network,
          'No internet connection. Check your network and try again.',
        );
    }
  }

  /// Builds an error from an HTTP status and the `{status, message, errors}` body.
  factory ApiException.fromResponse(int status, Object? body) {
    final map = asMap(body);
    final serverMessage = asString(map?['message'])?.trim();
    final fieldErrors = _parseFieldErrors(map?['errors']);

    String pick(String fallback) =>
        (serverMessage != null && serverMessage.isNotEmpty)
        ? serverMessage
        : fallback;

    switch (status) {
      case 401:
        return ApiException(
          ApiErrorKind.unauthorized,
          pick('Your session has ended. Please sign in again.'),
          statusCode: status,
        );
      case 422:
        // Prefer the first field message: it is the most specific.
        final first = fieldErrors.values
            .expand((l) => l)
            .firstWhere((m) => m.isNotEmpty, orElse: () => '');
        return ApiException(
          ApiErrorKind.validation,
          first.isNotEmpty ? first : pick('Please check what you entered.'),
          statusCode: status,
          fieldErrors: fieldErrors,
        );
      case 423:
        return ApiException(
          ApiErrorKind.locked,
          pick('Quoting is closed now.'),
          statusCode: status,
        );
      case 429:
        return ApiException(
          ApiErrorKind.rateLimited,
          'Too many tries. Please wait a minute and try again.',
          statusCode: status,
        );
      default:
        return ApiException(
          ApiErrorKind.server,
          status >= 500
              ? 'Something went wrong on the server. Please try again.'
              : pick('Something went wrong (error $status).'),
          statusCode: status,
        );
    }
  }

  static Map<String, List<String>> _parseFieldErrors(Object? raw) {
    final map = asMap(raw);
    if (map == null) return const {};
    return map.map((field, value) {
      final messages = switch (value) {
        List l => l.map((e) => e.toString()).toList(),
        null => <String>[],
        _ => [value.toString()],
      };
      return MapEntry(field, messages);
    });
  }

  @override
  String toString() => 'ApiException($kind, $statusCode): $message';
}

/// User-facing text for any error a screen might catch.
String errorMessage(Object error) => error is ApiException
    ? error.message
    : 'Something went wrong. Please try again.';
