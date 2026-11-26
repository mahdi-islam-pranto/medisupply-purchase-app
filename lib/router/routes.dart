/// All route paths in one place.
abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/sign-in';

  // Bottom-nav tabs
  static const home = '/home';
  static const quote = '/quote';
  static const history = '/history';
  static const reports = '/reports';
  static const profile = '/profile';

  // Under History
  static const approved = '/history/approved';
  static const approvedRange = '/history/approved-range';

  /// Approved quotes for one day (`null` = latest day with approvals).
  static String approvedFor(String? date) =>
      (date == null || date.isEmpty) ? approved : '$approved?date=$date';
}
