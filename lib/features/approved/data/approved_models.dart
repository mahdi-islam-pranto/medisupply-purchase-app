import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// One approved line: "Napa 500 mg — ৳620 × 40 = ৳24,800".
class ApprovedItem {
  const ApprovedItem({
    required this.productId,
    required this.name,
    this.brand,
    required this.qty,
    required this.unitPrice,
    required this.total,
  });

  final int productId;
  final String name;
  final String? brand;

  /// Approved qty (may be less than what the store offered).
  final num qty;
  final num unitPrice;
  final num total;

  factory ApprovedItem.fromJson(Json json) {
    final qty = asNum(json['qty']) ?? 0;
    final price = asNum(json['unit_price']) ?? 0;
    return ApprovedItem(
      productId: asInt(json['product_id']) ?? 0,
      name: asString(json['name']) ?? '',
      brand: asString(json['brand']),
      qty: qty,
      unitPrice: price,
      total: asNum(json['total']) ?? price * qty,
    );
  }
}

/// One day of approved quotes (`GET /approved` and each `days[]` entry
/// of `GET /approved/list`).
class ApprovedDay {
  const ApprovedDay({
    required this.date,
    required this.dateLabel,
    this.quoteNo,
    this.billNo,
    required this.totalItems,
    required this.approvedCount,
    required this.notApprovedCount,
    required this.pendingCount,
    required this.items,
    required this.total,
  });

  final String date;
  final String dateLabel;
  final String? quoteNo;

  /// Purchase bill made in the panel (`null` until there is one).
  final String? billNo;
  final int totalItems;
  final int approvedCount;
  final int notApprovedCount;
  final int pendingCount;
  final List<ApprovedItem> items;
  final num total;

  DateTime? get parsedDate => Fmt.parseDate(date);

  String get approvedText => '$approvedCount of $totalItems approved';

  factory ApprovedDay.fromJson(Json json) => ApprovedDay(
    date: asString(json['date']) ?? '',
    dateLabel: asString(json['date_label']) ?? '',
    quoteNo: asString(json['quote_no']),
    billNo: asString(json['bill_no']),
    totalItems: asInt(json['total_items']) ?? 0,
    approvedCount: asInt(json['approved_count']) ?? 0,
    notApprovedCount: asInt(json['not_approved_count']) ?? 0,
    pendingCount: asInt(json['pending_count']) ?? 0,
    items: asMapList(json['items']).map(ApprovedItem.fromJson).toList(),
    total: asNum(json['total']) ?? 0,
  );
}

/// `GET /approved/list` — approved days in a From–To range.
class ApprovedRangePage {
  const ApprovedRangePage({
    required this.rangeLabel,
    required this.days,
    required this.dayCount,
    required this.approvedLines,
    required this.amount,
    required this.page,
    required this.lastPage,
  });

  final String rangeLabel;
  final List<ApprovedDay> days;

  /// Summary for the whole range (all pages).
  final int dayCount;
  final int approvedLines;
  final num amount;
  final int page;
  final int lastPage;

  factory ApprovedRangePage.fromJson(Object? json) {
    final map = asMap(json) ?? const {};
    final summary = asMap(map['summary']) ?? const {};
    return ApprovedRangePage(
      rangeLabel: asString(map['range_label']) ?? '',
      days: asMapList(map['days']).map(ApprovedDay.fromJson).toList(),
      dayCount: asInt(summary['days']) ?? 0,
      approvedLines: asInt(summary['approved_lines']) ?? 0,
      amount: asNum(summary['amount']) ?? 0,
      page: asInt(map['page']) ?? 1,
      lastPage: asInt(map['last_page']) ?? 1,
    );
  }
}
