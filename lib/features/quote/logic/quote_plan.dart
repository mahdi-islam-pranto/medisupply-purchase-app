import '../../../core/utils/formatters.dart';
import '../data/quote_models.dart';

/// What the user typed for one product (both fields, as text).
class LineEdit {
  const LineEdit({required this.price, required this.qty});
  final String price;
  final String qty;
}

/// The state of one product card after combining server data with edits.
class LineView {
  const LineView({
    required this.product,
    required this.priceText,
    required this.qtyText,
    required this.isDirty,
    required this.missingPrice,
    required this.missingQty,
  });

  final QuoteProduct product;
  final String priceText;
  final String qtyText;

  /// Differs from what the server has → not sent yet.
  final bool isDirty;

  /// Only one of the two boxes is filled.
  final bool missingPrice;
  final bool missingQty;

  bool get isIncomplete => missingPrice || missingQty;
}

/// Pure "what will Send do" calculation, so it is easy to test.
///
/// Rules:
/// - a line with price > 0 and qty > 0 is sent;
/// - a line that was quoted and is now emptied is sent as 0/0 (removed);
/// - a line with only one of the two boxes filled blocks sending;
/// - approved/rejected (non-editable) lines are never sent.
class QuotePlan {
  QuotePlan._({
    required this.lines,
    required this.items,
    required this.filledCount,
    required this.removedCount,
    required this.incompleteIds,
    required this.hasChanges,
    required this.noteToSend,
  });

  final Map<int, LineView> lines;
  final List<QuoteItem> items;
  final int filledCount;
  final int removedCount;
  final List<int> incompleteIds;
  final bool hasChanges;

  /// `null` when the note was not touched.
  final String? noteToSend;

  bool get canSend => hasChanges && items.isNotEmpty && incompleteIds.isEmpty;

  /// "Send 8 quotes", "Send 1 quote", "Update quotes", ...
  String get buttonLabel {
    if (!hasChanges) return 'Send quotes';
    if (filledCount > 0) {
      return 'Send $filledCount ${filledCount == 1 ? 'quote' : 'quotes'}';
    }
    if (removedCount > 0) return 'Update quotes';
    return 'Send quotes';
  }

  factory QuotePlan.build({
    required List<QuoteProduct> products,
    required Map<int, LineEdit> edits,
    String? note,
    String? serverNote,
  }) {
    final lines = <int, LineView>{};
    final items = <QuoteItem>[];
    final incomplete = <int>[];
    var filled = 0;
    var removed = 0;
    var changed = false;

    for (final p in products) {
      final edit = edits[p.productId];
      final priceText = edit?.price ?? Fmt.plain(p.myPrice);
      final qtyText = edit?.qty ?? Fmt.plain(p.myQty);
      final price = num.tryParse(priceText.trim()) ?? 0;
      final qty = num.tryParse(qtyText.trim()) ?? 0;
      final hasPrice = price > 0;
      final hasQty = qty > 0;

      final dirty =
          p.editable && (price != (p.myPrice ?? 0) || qty != (p.myQty ?? 0));

      lines[p.productId] = LineView(
        product: p,
        priceText: priceText,
        qtyText: qtyText,
        isDirty: dirty,
        missingPrice: p.editable && !hasPrice && hasQty,
        missingQty: p.editable && hasPrice && !hasQty,
      );

      if (!p.editable) continue;
      if (dirty) changed = true;

      if (hasPrice && hasQty) {
        filled++;
        items.add(QuoteItem(productId: p.productId, price: price, qty: qty));
      } else if (hasPrice != hasQty) {
        incomplete.add(p.productId);
      } else if (p.isQuoted) {
        removed++;
        items.add(QuoteItem(productId: p.productId, price: 0, qty: 0));
      }
    }

    String? noteToSend;
    if (note != null && note.trim() != (serverNote ?? '').trim()) {
      noteToSend = note.trim();
      changed = true;
    }

    return QuotePlan._(
      lines: lines,
      items: items,
      filledCount: filled,
      removedCount: removed,
      incompleteIds: incomplete,
      hasChanges: changed,
      noteToSend: noteToSend,
    );
  }
}
