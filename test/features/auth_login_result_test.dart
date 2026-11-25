import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_app/core/network/api_exception.dart';
import 'package:purchase_app/features/auth/data/auth_repository.dart';

void main() {
  test('parses /login data', () {
    final r = LoginResult.fromJson({
      'store_key': 'eyJpdiI6abc',
      'store': {
        'name': 'Green Corner Store',
        'company': null,
        'phone': '01712345678',
        'email': 'store@example.com',
      },
    });
    expect(r.storeKey, 'eyJpdiI6abc');
    expect(r.store?.name, 'Green Corner Store');
    expect(r.store?.phone, '01712345678');
  });

  test('missing store_key is an error', () {
    expect(
      () => LoginResult.fromJson({'store': null}),
      throwsA(isA<ApiException>()),
    );
  });
}
