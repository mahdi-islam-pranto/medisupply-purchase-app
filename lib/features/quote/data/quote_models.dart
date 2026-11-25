import '../../../core/models/quote_window.dart';
import '../../../core/utils/json.dart';

/// One product on today's list (`products[]` in `GET /quote`).
class QuoteProduct {
  const QuoteProduct({
    required this.productId,
    required this.name,
    this.brand,
    this.imageUrl,
    this.neededQty,
    this.requestNote,
    this.myPrice,
    this.myQty,
    required this.status,
    required this.editable,
  });

  final int productId;
  final String name;
  final String? brand;
  final String? imageUrl;

  /// How many MediSupply wants (`null` = not set).
  final num? neededQty;
  final String? requestNote;

  /// What this store already sent (`null` = not quoted yet).
  final num? myPrice;
  final num? myQty;

  /// `needs_price`, `done`, `approved` or `rejected`.
  final String status;

  /// `false` once approved/rejected: show read-only.
  final bool editable;

  bool get isQuoted => (myPrice ?? 0) > 0 && (myQty ?? 0) > 0;

  factory QuoteProduct.fromJson(Json json) => QuoteProduct(
    productId: asInt(json['product_id']) ?? 0,
    name: asString(json['name']) ?? '',
    brand: asString(json['brand']),
    imageUrl: asString(json['image_url']),
    neededQty: asNum(json['needed_qty']),
    requestNote: asString(json['request_note']),
    myPrice: asNum(json['my_price']),
    myQty: asNum(json['my_qty']),
    status: asString(json['status']) ?? 'needs_price',
    editable: asBool(json['editable'], fallback: true),
  );
}

/// What the store already sent today (`todays_quote`).
class TodaysQuote {
  const TodaysQuote({
    this.quoteNo,
    required this.items,
    this.sentAt,
    required this.status,
    required this.statusLabel,
    this.note,
  });

  final String? quoteNo;
  final int items;

  /// `"11:42"`
  final String? sentAt;
  final String status;
  final String statusLabel;
  final String? note;

  factory TodaysQuote.fromJson(Json json) => TodaysQuote(
    quoteNo: asString(json['quote_no']),
    items: asInt(json['items']) ?? 0,
    sentAt: asString(json['sent_at']),
    status: asString(json['status']) ?? 'pending',
    statusLabel: asString(json['status_label']) ?? '',
    note: asString(json['note']),
  );
}

/// `GET /quote`
class QuoteData {
  const QuoteData({
    required this.date,
    required this.dateLabel,
    required this.window,
    required this.total,
    required this.priced,
    required this.products,
    this.todaysQuote,
  });

  final String date;
  final String dateLabel;
  final QuoteWindow window;
  final int total;
  final int priced;
  final List<QuoteProduct> products;
  final TodaysQuote? todaysQuote;

  factory QuoteData.fromJson(Object? json, {DateTime? now}) {
    final map = asMap(json) ?? const {};
    final products = asMapList(map['products']).map(QuoteProduct.fromJson);
    final today = asMap(map['todays_quote']);
    return QuoteData(
      date: asString(map['date']) ?? '',
      dateLabel: asString(map['date_label']) ?? '',
      window: QuoteWindow.fromJson(map['window'], now: now),
      total: asInt(map['total']) ?? 0,
      priced: asInt(map['priced']) ?? 0,
      products: products.toList(growable: false),
      todaysQuote: today == null ? null : TodaysQuote.fromJson(today),
    );
  }
}

/// One line of `POST /quote`. `0/0` takes the product off the quote.
class QuoteItem {
  const QuoteItem({
    required this.productId,
    required this.price,
    required this.qty,
  });

  final int productId;
  final num price;
  final num qty;

  Json toJson() => {'product_id': productId, 'price': price, 'qty': qty};
}

/// Reply of `POST /quote`.
class SendQuoteResult {
  const SendQuoteResult({
    required this.message,
    this.quoteNo,
    required this.items,
    this.sentAt,
  });

  final String message;
  final String? quoteNo;
  final int items;
  final String? sentAt;
}
