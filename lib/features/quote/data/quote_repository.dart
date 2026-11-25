import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import 'quote_models.dart';

final quoteRepositoryProvider = Provider<QuoteRepository>(
  (ref) => QuoteRepository(ref.watch(apiClientProvider)),
);

class QuoteRepository {
  QuoteRepository(this._api);

  final ApiClient _api;

  /// Today's full list. (Search is done on the phone, so typed prices
  /// are never lost while filtering.)
  Future<QuoteData> fetch() async {
    final res = await _api.get('/quote', parse: QuoteData.fromJson);
    return res.data;
  }

  /// Sends/updates quote lines. Throws ApiException 423 when the window
  /// is closed and 422 when none of the lines can be quoted.
  Future<SendQuoteResult> send(List<QuoteItem> items, {String? note}) async {
    final res = await _api.post(
      '/quote',
      body: {'items': items.map((i) => i.toJson()).toList(), 'note': ?note},
      parse: (data) => asMap(data) ?? const <String, dynamic>{},
    );
    final d = res.data;
    return SendQuoteResult(
      message: res.message.isEmpty ? 'Quotes sent' : res.message,
      quoteNo: asString(d['quote_no']),
      items: asInt(d['items']) ?? items.length,
      sentAt: asString(d['sent_at']),
    );
  }
}
