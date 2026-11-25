import '../utils/json.dart';

/// Sales / Received / Due for a period (`today` on Home, `summary` on Reports).
class MoneySummary {
  const MoneySummary({
    required this.sales,
    required this.received,
    required this.due,
  });

  static const zero = MoneySummary(sales: 0, received: 0, due: 0);

  final num sales;
  final num received;
  final num due;

  factory MoneySummary.fromJson(Object? json) {
    final map = asMap(json);
    if (map == null) return zero;
    return MoneySummary(
      sales: asNum(map['sales']) ?? 0,
      received: asNum(map['received']) ?? 0,
      due: asNum(map['due']) ?? 0,
    );
  }
}
