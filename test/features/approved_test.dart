import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_app/features/approved/data/approved_models.dart';

void main() {
  test('parses /approved day', () {
    final d = ApprovedDay.fromJson({
      'date': '2026-11-19',
      'date_label': 'Thu, 19 Nov 2026',
      'quote_no': 'SQ-000041',
      'bill_no': 'PUR-000182',
      'total_items': 8,
      'approved_count': 5,
      'not_approved_count': 3,
      'pending_count': 0,
      'items': [
        {
          'product_id': 120,
          'name': 'Napa 500 mg (100 pcs)',
          'brand': 'Beximco',
          'qty': 40,
          'unit_price': 620,
          'total': 24800,
        },
      ],
      'total': 63925,
    });
    expect(d.approvedText, '5 of 8 approved');
    expect(d.items.single.total, 24800);
    expect(d.billNo, 'PUR-000182');
    expect(d.notApprovedCount, 3);
  });

  test('parses /approved/list page with summary', () {
    final r = ApprovedRangePage.fromJson({
      'from': '2026-11-01',
      'to': '2026-11-20',
      'range_label': '01 Nov 2026 – 20 Nov 2026',
      'summary': {'days': 12, 'approved_lines': 64, 'amount': 742150},
      'days': [
        {
          'date': '2026-11-19',
          'total_items': 8,
          'approved_count': 5,
          'items': [],
          'total': 63925,
        },
      ],
      'page': 1,
      'last_page': 2,
    });
    expect(r.dayCount, 12);
    expect(r.amount, 742150);
    expect(r.days.single.total, 63925);
    expect(r.lastPage, 2);
  });
}
