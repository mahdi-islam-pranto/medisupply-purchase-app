import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_app/core/utils/validators.dart';

void main() {
  group('phoneOrEmail', () {
    test('accepts phone numbers in common formats', () {
      expect(Validators.phoneOrEmail('01712345678'), isNull);
      expect(Validators.phoneOrEmail('017-1234 5678'), isNull);
      expect(Validators.phoneOrEmail('+8801712345678'), isNull);
    });
    test('accepts email', () {
      expect(Validators.phoneOrEmail('store@example.com'), isNull);
    });
    test('rejects bad input', () {
      expect(Validators.phoneOrEmail(''), isNotNull);
      expect(Validators.phoneOrEmail('12345'), isNotNull);
      expect(Validators.phoneOrEmail('store@'), isNotNull);
      expect(Validators.phoneOrEmail('green store'), isNotNull);
    });
  });

  test('newPin needs 6+ characters', () {
    expect(Validators.newPin('12345'), isNotNull);
    expect(Validators.newPin('123456'), isNull);
  });
}
