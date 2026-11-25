import '../../../core/models/money_summary.dart';
import '../../../core/models/quote_summary.dart';
import '../../../core/models/quote_window.dart';
import '../../../core/session/store_info.dart';
import '../../../core/utils/json.dart';

/// `GET /home`
class HomeData {
  const HomeData({
    required this.store,
    required this.date,
    required this.dateLabel,
    required this.window,
    required this.productsToQuote,
    required this.priced,
    required this.canQuote,
    required this.today,
    required this.totalDue,
    required this.lastQuote,
  });

  final StoreInfo? store;
  final String date;
  final String dateLabel;
  final QuoteWindow window;
  final int productsToQuote;
  final int priced;
  final bool canQuote;
  final MoneySummary today;
  final num totalDue;
  final QuoteSummary? lastQuote;

  factory HomeData.fromJson(Object? json, {DateTime? now}) {
    final map = asMap(json) ?? const {};
    final store = asMap(map['store']);
    final last = asMap(map['last_quote']);
    return HomeData(
      store: store == null ? null : StoreInfo.fromJson(store),
      date: asString(map['date']) ?? '',
      dateLabel: asString(map['date_label']) ?? '',
      window: QuoteWindow.fromJson(map['window'], now: now),
      productsToQuote: asInt(map['products_to_quote']) ?? 0,
      priced: asInt(map['priced']) ?? 0,
      canQuote: asBool(map['can_quote']),
      today: MoneySummary.fromJson(map['today']),
      totalDue: asNum(map['total_due']) ?? 0,
      lastQuote: last == null ? null : QuoteSummary.fromJson(last),
    );
  }
}
