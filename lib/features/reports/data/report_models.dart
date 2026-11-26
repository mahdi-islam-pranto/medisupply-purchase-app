import '../../../core/models/money_summary.dart';
import '../../../core/utils/json.dart';

/// The three report ranges the server supports.
enum ReportPeriod {
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly');

  const ReportPeriod(this.apiValue, this.label);

  /// Value for `?period=`.
  final String apiValue;

  /// Text on the segmented control.
  final String label;

  static ReportPeriod fromApi(String? value) => ReportPeriod.values.firstWhere(
    (p) => p.apiValue == value,
    orElse: () => ReportPeriod.daily,
  );
}

/// One table row: a day, a week or a month.
class ReportRow {
  const ReportRow({
    required this.label,
    required this.from,
    required this.to,
    required this.sales,
    required this.received,
    required this.due,
  });

  final String label;

  /// `Y-m-d`.
  final String? from;
  final String? to;

  final num sales;
  final num received;

  /// This row's Sales − Received (not the store's total balance).
  final num due;

  factory ReportRow.fromJson(Json json) => ReportRow(
    label: asString(json['label']) ?? asString(json['from']) ?? '',
    from: asString(json['from']),
    to: asString(json['to']),
    sales: asNum(json['sales']) ?? 0,
    received: asNum(json['received']) ?? 0,
    due: asNum(json['due']) ?? 0,
  );
}

/// `GET /reports` — rows are newest first.
class ReportData {
  const ReportData({
    required this.period,
    required this.rangeLabel,
    required this.summary,
    required this.rows,
  });

  final ReportPeriod period;
  final String? rangeLabel;
  final MoneySummary summary;
  final List<ReportRow> rows;

  factory ReportData.fromJson(Object? json, {ReportPeriod? requested}) {
    final map = asMap(json) ?? const {};
    final period = map['period'] == null
        ? (requested ?? ReportPeriod.daily)
        : ReportPeriod.fromApi(asString(map['period']));
    return ReportData(
      period: period,
      rangeLabel: asString(map['range_label']),
      summary: MoneySummary.fromJson(map['summary']),
      rows: asMapList(map['rows']).map(ReportRow.fromJson).toList(),
    );
  }
}
