import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_app/core/utils/formatters.dart';

void main() {
  group('Fmt.money', () {
    test('adds taka sign and commas', () {
      expect(Fmt.money(63925), '৳63,925');
      expect(Fmt.money(184500), '৳184,500');
      expect(Fmt.money(0), '৳0');
    });
    test('keeps decimals only when needed', () {
      expect(Fmt.money(63925.5), '৳63,925.5');
      expect(Fmt.money(620.0), '৳620');
    });
    test('negative and null', () {
      expect(Fmt.money(-500), '-৳500');
      expect(Fmt.money(null), '৳—');
    });
  });

  test('Fmt.countdown', () {
    expect(Fmt.countdown(8048), '02:14:08');
    expect(Fmt.countdown(0), '00:00:00');
    expect(Fmt.countdown(-5), '00:00:00');
    expect(Fmt.countdown(64800), '18:00:00');
  });

  test('dates', () {
    final d = DateTime(2026, 11, 20);
    expect(Fmt.apiDate(d), '2026-11-20');
    expect(Fmt.dayMonth(d), '20 Nov');
    expect(Fmt.dayMonthYear(d), '20 Nov 2026');
    expect(Fmt.parseDate('2026-11-19'), DateTime(2026, 11, 19));
    expect(Fmt.parseDate('bad'), isNull);
  });
}
