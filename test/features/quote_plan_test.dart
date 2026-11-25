import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_app/features/quote/data/quote_models.dart';
import 'package:purchase_app/features/quote/logic/quote_plan.dart';

QuoteProduct product(
  int id, {
  num? price,
  num? qty,
  bool editable = true,
  String status = 'needs_price',
}) => QuoteProduct(
  productId: id,
  name: 'P$id',
  myPrice: price,
  myQty: qty,
  status: status,
  editable: editable,
);

void main() {
  final products = [
    product(1, price: 620, qty: 40, status: 'done'),
    product(2, price: 845, qty: 25, status: 'done'),
    product(3),
    product(4, price: 100, qty: 5, status: 'approved', editable: false),
  ];

  test('no edits → nothing to send', () {
    final plan = QuotePlan.build(products: products, edits: {});
    expect(plan.hasChanges, isFalse);
    expect(plan.filledCount, 2);
    expect(plan.lines[1]!.priceText, '620');
    expect(plan.lines[3]!.priceText, '');
  });

  test('new line + resend existing, approved line never sent', () {
    final plan = QuotePlan.build(
      products: products,
      edits: {3: const LineEdit(price: '130.5', qty: '60')},
    );
    expect(plan.hasChanges, isTrue);
    expect(plan.canSend, isTrue);
    expect(plan.filledCount, 3);
    expect(plan.buttonLabel, 'Send 3 quotes');
    expect(plan.items.map((i) => i.productId), [1, 2, 3]);
    expect(plan.items.last.price, 130.5);
    expect(plan.lines[3]!.isDirty, isTrue);
    expect(plan.lines[1]!.isDirty, isFalse);
  });

  test('clearing a quoted line sends 0/0', () {
    final plan = QuotePlan.build(
      products: products,
      edits: {2: const LineEdit(price: '', qty: '')},
    );
    final removed = plan.items.firstWhere((i) => i.productId == 2);
    expect(removed.price, 0);
    expect(removed.qty, 0);
    expect(plan.removedCount, 1);
    expect(plan.filledCount, 1);
  });

  test('price without qty blocks sending', () {
    final plan = QuotePlan.build(
      products: products,
      edits: {3: const LineEdit(price: '50', qty: '')},
    );
    expect(plan.incompleteIds, [3]);
    expect(plan.canSend, isFalse);
    expect(plan.lines[3]!.missingQty, isTrue);
    expect(plan.lines[3]!.missingPrice, isFalse);
  });

  test('note change alone counts as a change', () {
    final plan = QuotePlan.build(
      products: products,
      edits: {},
      note: 'After 3 PM',
      serverNote: null,
    );
    expect(plan.hasChanges, isTrue);
    expect(plan.noteToSend, 'After 3 PM');
    expect(plan.canSend, isTrue);
  });

  test('parses /quote sample', () {
    final d = QuoteData.fromJson({
      'date': '2026-11-20',
      'window': {
        'open': true,
        'opens_at': '10:00',
        'closes_at': '14:00',
        'seconds_left': 8048,
      },
      'total': 8,
      'priced': 3,
      'products': [
        {
          'product_id': 120,
          'name': 'Napa 500 mg (100 pcs)',
          'brand': 'Beximco',
          'image_url': null,
          'needed_qty': 40,
          'request_note': 'Box of 100 preferred',
          'my_price': 620,
          'my_qty': 40,
          'status': 'done',
          'editable': true,
        },
      ],
      'todays_quote': {
        'quote_no': 'SQ-000052',
        'items': 3,
        'sent_at': '11:42',
        'status': 'pending',
        'status_label': 'Pending',
        'note': null,
      },
    });
    expect(d.products.single.isQuoted, isTrue);
    expect(d.products.single.neededQty, 40);
    expect(d.todaysQuote?.sentAt, '11:42');
  });
}
