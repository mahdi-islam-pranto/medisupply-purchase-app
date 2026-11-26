import '../../../core/models/quote_window.dart';
import '../../../core/session/store_info.dart';
import '../../../core/utils/json.dart';

enum NotificationType { quoteReviewed, window, payment, other }

/// One line in the Profile notifications list.
class AppNotification {
  const AppNotification({
    required this.type,
    required this.title,
    required this.body,
    this.at,
    this.timeAgo,
  });

  final NotificationType type;
  final String title;
  final String body;

  /// ISO time, e.g. `2026-11-20T09:15:00+06:00`.
  final String? at;

  /// "2 hours ago", from the server.
  final String? timeAgo;

  static NotificationType _type(String? v) => switch (v) {
    'quote_reviewed' => NotificationType.quoteReviewed,
    'window' => NotificationType.window,
    'payment' => NotificationType.payment,
    _ => NotificationType.other,
  };

  factory AppNotification.fromJson(Json json) => AppNotification(
    type: _type(asString(json['type'])),
    title: asString(json['title']) ?? '',
    body: asString(json['body']) ?? '',
    at: asString(json['at']),
    timeAgo: asString(json['time_ago']),
  );
}

/// `GET /profile`.
class ProfileData {
  const ProfileData({
    required this.store,
    required this.window,
    required this.notifications,
  });

  final StoreInfo? store;
  final QuoteWindow window;
  final List<AppNotification> notifications;

  factory ProfileData.fromJson(Object? json, {DateTime? now}) {
    final map = asMap(json) ?? const {};
    final store = asMap(map['store']);
    return ProfileData(
      store: store == null ? null : StoreInfo.fromJson(store),
      window: QuoteWindow.fromJson(map['window'], now: now),
      notifications: asMapList(map['notifications'])
          .map(AppNotification.fromJson)
          .toList(),
    );
  }
}
