import 'package:intl/intl.dart';

/// Money, date and countdown formatting used across the app.
abstract final class Fmt {
  static const String taka = '৳';

  static final NumberFormat _whole = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimal = NumberFormat('#,##0.##', 'en_US');
  static final DateFormat _api = DateFormat('yyyy-MM-dd');
  static final DateFormat _dayMonth = DateFormat('d MMM', 'en_US');
  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy', 'en_US');

  /// `63925` → `63,925`, `63925.5` → `63,925.5`.
  static String number(num value) {
    final isWhole = value == value.roundToDouble();
    return (isWhole ? _whole : _decimal).format(value);
  }

  /// Number for an input box, no commas: `620` → `620`, `620.5` → `620.5`,
  /// `null` → empty.
  static String plain(num? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  /// `63925` → `৳63,925`, `-500` → `-৳500`, `null` → `৳—`.
  static String money(num? value, {String empty = '$taka—'}) {
    if (value == null) return empty;
    if (value < 0) return '-$taka${number(value.abs())}';
    return '$taka${number(value)}';
  }

  /// Date for API parameters: `2026-11-20`.
  static String apiDate(DateTime date) => _api.format(date);

  /// Parses an API date (`2026-11-20`) or date-time; `null` if invalid.
  static DateTime? parseDate(String? value) =>
      value == null ? null : DateTime.tryParse(value);

  /// `20 Nov`
  static String dayMonth(DateTime date) => _dayMonth.format(date);

  /// `20 Nov 2026`
  static String dayMonthYear(DateTime date) => _dayMonthYear.format(date);

  /// Seconds → `02:14:08`. Negative values show `00:00:00`.
  static String countdown(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
  }
}
