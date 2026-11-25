import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_app/core/network/api_exception.dart';

void main() {
  test('401 uses server message', () {
    final e = ApiException.fromResponse(401, {
      'status': 401,
      'message': 'Phone number / email or PIN is not correct.',
      'data': null,
    });
    expect(e.kind, ApiErrorKind.unauthorized);
    expect(e.message, 'Phone number / email or PIN is not correct.');
  });

  test('422 exposes field errors', () {
    final e = ApiException.fromResponse(422, {
      'status': 422,
      'message': 'The given data was invalid.',
      'errors': {
        'new_pin': ['The new pin must be at least 6 characters.'],
      },
    });
    expect(e.kind, ApiErrorKind.validation);
    expect(
      e.fieldError('new_pin'),
      'The new pin must be at least 6 characters.',
    );
    expect(e.message, 'The new pin must be at least 6 characters.');
    expect(e.fieldError('current_pin'), isNull);
  });

  test('423 window closed', () {
    final e = ApiException.fromResponse(423, {
      'message': 'Quoting is closed now. It opens at 10:00.',
    });
    expect(e.kind, ApiErrorKind.locked);
    expect(e.message, 'Quoting is closed now. It opens at 10:00.');
  });

  test('429 and 500 use friendly text, non-JSON body ok', () {
    expect(
      ApiException.fromResponse(429, '<html>').kind,
      ApiErrorKind.rateLimited,
    );
    final e = ApiException.fromResponse(500, null);
    expect(e.kind, ApiErrorKind.server);
    expect(e.message, contains('server'));
  });
}
