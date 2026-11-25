import '../utils/formatters.dart';
import '../utils/json.dart';

/// One day's quote result: `last_quote` on Home and each row of History.
class QuoteSummary {
  const QuoteSummary({
    required this.date,
    required this.dateLabel,
    required this.quoteNo,
    required this.totalItems,
    required this.approvedCount,
    required this.rejectedCount,
    required this.pendingCount,
    required this.approvedAmount,
    required this.status,
    required this.statusLabel,
    this.pdfUrl,
  });

  /// `2026-11-19`
  final String date;

  /// `Thu, 19 Nov 2026`
  final String dateLabel;
  final String? quoteNo;
  final int totalItems;
  final int approvedCount;
  final int rejectedCount;
  final int pendingCount;
  final num approvedAmount;

  /// `pending`, `approved`, `partial` or `rejected`.
  final String status;
  final String statusLabel;
  final String? pdfUrl;

  DateTime? get parsedDate => Fmt.parseDate(date);

  /// "5 of 8 approved"
  String get approvedText => '$approvedCount of $totalItems approved';

  /// "৳63,925", or "৳—" when nothing is approved yet.
  String get amountText =>
      approvedAmount > 0 ? Fmt.money(approvedAmount) : Fmt.money(null);

  factory QuoteSummary.fromJson(Object? json) {
    final map = asMap(json) ?? const {};
    return QuoteSummary(
      date: asString(map['date']) ?? '',
      dateLabel: asString(map['date_label']) ?? '',
      quoteNo: asString(map['quote_no']),
      totalItems: asInt(map['total_items']) ?? 0,
      approvedCount: asInt(map['approved_count']) ?? 0,
      rejectedCount: asInt(map['rejected_count']) ?? 0,
      pendingCount: asInt(map['pending_count']) ?? 0,
      approvedAmount: asNum(map['approved_amount']) ?? 0,
      status: asString(map['status']) ?? 'pending',
      statusLabel: asString(map['status_label']) ?? '',
      pdfUrl: asString(map['pdf_url']),
    );
  }
}
