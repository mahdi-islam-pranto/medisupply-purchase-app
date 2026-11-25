import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_app/features/quote/data/quote_models.dart';
import 'package:purchase_app/features/quote/logic/quote_plan.dart';
import 'package:purchase_app/features/quote/presentation/widgets/product_quote_card.dart';

Future<void> pumpCard(WidgetTester tester, QuoteProduct p) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final plan = QuotePlan.build(products: [p], edits: {});
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProductQuoteCard(
          line: plan.lines[p.productId]!,
          showErrors: false,
          onChanged: (_, _) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('short name: no expand arrow', (tester) async {
    await pumpCard(
      tester,
      const QuoteProduct(
        productId: 1,
        name: 'Napa 500 mg',
        status: 'needs_price',
        editable: true,
      ),
    );
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
  });

  testWidgets('long name: arrow shown, tap shows full name', (tester) async {
    const longName =
        'Paracetamol 500 mg + Caffeine 65 mg Film Coated Tablet, Extra Strength '
        'Formula, Family Pack of 10 strips x 10 tablets';
    await pumpCard(
      tester,
      const QuoteProduct(
        productId: 2,
        name: longName,
        brand: 'Beximco Pharmaceuticals Ltd.',
        status: 'needs_price',
        editable: true,
      ),
    );
    final text = tester.widget<Text>(find.text(longName));
    expect(text.maxLines, 2);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

    await tester.tap(find.text(longName));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.text(longName)).maxLines, isNull);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
  });
}
