import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../data/quote_models.dart';
import '../data/quote_repository.dart';
import '../logic/quote_plan.dart';

/// Today's products and window (`GET /quote`).
final quoteProvider = FutureProvider<QuoteData>((ref) async {
  ref.watch(sessionProvider.select((s) => s.storeKey));
  return ref.read(quoteRepositoryProvider).fetch();
});

/// What the user has typed but not sent yet. Lives outside the screen,
/// so switching tabs never loses typed prices.
class QuoteFormState {
  const QuoteFormState({
    this.edits = const {},
    this.note,
    this.search = '',
    this.showErrors = false,
    this.sending = false,
  });

  final Map<int, LineEdit> edits;

  /// `null` = note not touched.
  final String? note;
  final String search;

  /// Turned on after a Send with incomplete lines.
  final bool showErrors;
  final bool sending;

  QuoteFormState copyWith({
    Map<int, LineEdit>? edits,
    String? note,
    String? search,
    bool? showErrors,
    bool? sending,
  }) => QuoteFormState(
    edits: edits ?? this.edits,
    note: note ?? this.note,
    search: search ?? this.search,
    showErrors: showErrors ?? this.showErrors,
    sending: sending ?? this.sending,
  );
}

final quoteFormProvider = NotifierProvider<QuoteFormController, QuoteFormState>(
  QuoteFormController.new,
);

class QuoteFormController extends Notifier<QuoteFormState> {
  @override
  QuoteFormState build() {
    // Start fresh for a different store.
    ref.watch(sessionProvider.select((s) => s.storeKey));
    return const QuoteFormState();
  }

  void setLine(int productId, {required String price, required String qty}) {
    state = state.copyWith(
      edits: {
        ...state.edits,
        productId: LineEdit(price: price, qty: qty),
      },
    );
  }

  void setNote(String note) => state = state.copyWith(note: note);

  void setSearch(String q) => state = state.copyWith(search: q);

  void showErrors() => state = state.copyWith(showErrors: true);

  void setSending(bool v) => state = state.copyWith(sending: v);

  /// After a successful send (or when the window closes).
  void clearEdits() => state = QuoteFormState(search: state.search);
}

/// The combined view of server data + typed edits.
final quotePlanProvider = Provider<QuotePlan?>((ref) {
  final data = ref.watch(quoteProvider).value;
  if (data == null) return null;
  final form = ref.watch(quoteFormProvider);
  return QuotePlan.build(
    products: data.products,
    edits: form.edits,
    note: form.note,
    serverNote: data.todaysQuote?.note,
  );
});
