import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_app/features/home/data/home_data.dart';

void main() {
  final now = DateTime(2026, 11, 20, 11, 45, 52);

  final sample = {
    'store': {
      'name': 'Green Corner Store',
      'company': null,
      'phone': '01712345678',
      'email': null,
    },
    'date': '2026-11-20',
    'date_label': 'Fri, 20 Nov 2026',
    'window': {
      'open': true,
      'opens_at': '10:00',
      'closes_at': '14:00',
      'next_change': '2026-11-20T14:00:00+06:00',
      'seconds_left': 8048,
      'label': 'Window open · closes 14:00',
    },
    'products_to_quote': 8,
    'priced': 3,
    'can_quote': true,
    'today': {'sales': 63925, 'received': 40000, 'due': 23925},
    'total_due': 184500,
    'last_quote': {
      'date': '2026-11-19',
      'date_label': 'Thu, 19 Nov 2026',
      'quote_no': 'SQ-000041',
      'total_items': 8,
      'approved_count': 5,
      'rejected_count': 3,
      'pending_count': 0,
      'approved_amount': 63925,
      'status': 'partial',
      'status_label': 'Partly approved',
    },
  };

  test('parses the /home sample from the API guide', () {
    final d = HomeData.fromJson(sample, now: now);
    expect(d.store?.name, 'Green Corner Store');
    expect(d.window.open, isTrue);
    expect(d.window.label, 'Window open · closes 14:00');
    expect(d.window.deadline, now.add(const Duration(seconds: 8048)));
    expect(d.productsToQuote, 8);
    expect(d.priced, 3);
    expect(d.canQuote, isTrue);
    expect(d.today.due, 23925);
    expect(d.totalDue, 184500);
    expect(d.lastQuote?.approvedText, '5 of 8 approved');
    expect(d.lastQuote?.amountText, '৳63,925');
  });

  test('handles null last_quote, string numbers and missing label', () {
    final d = HomeData.fromJson({
      ...sample,
      'last_quote': null,
      'total_due': '1500.50',
      'window': {
        'open': false,
        'opens_at': '10:00',
        'closes_at': '14:00',
        'seconds_left': 100,
      },
    }, now: now);
    expect(d.lastQuote, isNull);
    expect(d.totalDue, 1500.5);
    expect(d.window.label, 'Quoting is closed · opens 10:00');
    expect(d.window.range, '10:00 – 14:00');
  });
}
