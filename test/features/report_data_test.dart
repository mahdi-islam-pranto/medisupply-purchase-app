import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_app/features/reports/data/report_models.dart';

void main() {
  test('parses the /reports response', () {
    final data = ReportData.fromJson({
      'period': 'weekly',
      'range_label': 'Last 8 weeks · 3 Oct–27 Nov',
      'summary': {'sales': '423775.00', 'received': 327500, 'due': 96275},
      'rows': [
        {
          'label': '20 Nov',
          'from': '2026-11-20',
          'to': '2026-11-20',
          'sales': 63925,
          'received': 40000,
          'due': 23925,
        },
        {'label': '19 Nov', 'sales': 58400, 'received': 58400, 'due': 0},
      ],
    });

    expect(data.period, ReportPeriod.weekly);
    expect(data.rangeLabel, 'Last 8 weeks · 3 Oct–27 Nov');
    expect(data.summary.sales, 423775);
    expect(data.summary.due, 96275);
    expect(data.rows, hasLength(2));
    expect(data.rows.first.from, '2026-11-20');
    expect(data.rows.first.due, 23925);
    expect(data.rows.last.due, 0);
  });

  test('falls back to the requested period and empty rows', () {
    final data = ReportData.fromJson({}, requested: ReportPeriod.monthly);
    expect(data.period, ReportPeriod.monthly);
    expect(data.rows, isEmpty);
    expect(data.summary.sales, 0);
  });

  test('unknown period value maps to daily', () {
    expect(ReportPeriod.fromApi('yearly'), ReportPeriod.daily);
    expect(ReportPeriod.fromApi('monthly'), ReportPeriod.monthly);
  });
}
