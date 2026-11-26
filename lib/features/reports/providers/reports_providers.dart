import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../data/report_models.dart';
import '../data/reports_repository.dart';

/// The selected Daily / Weekly / Monthly tab. Not auto-disposed, so the
/// choice survives switching bottom tabs.
final reportPeriodProvider =
    NotifierProvider<ReportPeriodController, ReportPeriod>(
      ReportPeriodController.new,
    );

class ReportPeriodController extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() {
    // Back to Daily when another store signs in.
    ref.watch(sessionProvider.select((s) => s.storeKey));
    return ReportPeriod.daily;
  }

  void select(ReportPeriod period) => state = period;
}

/// One report per period. Kept while the app runs so flipping between
/// periods is instant; pull-to-refresh reloads the visible one.
final reportProvider = FutureProvider.family<ReportData, ReportPeriod>((
  ref,
  period,
) {
  ref.watch(sessionProvider.select((s) => s.storeKey));
  return ref.read(reportsRepositoryProvider).report(period);
});
