import '../utils/json.dart';

/// The daily quote window (same for every store), from `window` in
/// `/home`, `/quote` and `/profile`.
class QuoteWindow {
  const QuoteWindow({
    required this.open,
    required this.opensAt,
    required this.closesAt,
    required this.secondsLeft,
    required this.deadline,
    this.nextChange,
    this._label,
  });

  /// `true` while quotes can be sent.
  final bool open;

  /// `"10:00"` / `"14:00"` (Bangladesh time).
  final String opensAt;
  final String closesAt;

  /// Seconds until the window opens or closes (at the time of the call).
  final int secondsLeft;

  /// When the window flips, on the phone's clock: now + [secondsLeft].
  /// Using the phone clock + seconds avoids time-zone mistakes.
  final DateTime deadline;

  /// ISO time of the next change, e.g. `2026-11-20T14:00:00+06:00`.
  final String? nextChange;

  final String? _label;

  /// "Window open · closes 14:00" or "Quoting is closed · opens 10:00".
  String get label =>
      (_label != null && _label.isNotEmpty) ? _label : fallbackLabel;

  String get fallbackLabel => open
      ? 'Window open · closes $closesAt'
      : 'Quoting is closed · opens $opensAt';

  /// "10:00 – 14:00"
  String get range => '$opensAt – $closesAt';

  factory QuoteWindow.fromJson(Object? json, {DateTime? now}) {
    final map = asMap(json) ?? const {};
    final seconds = asInt(map['seconds_left']) ?? 0;
    return QuoteWindow(
      open: asBool(map['open']),
      opensAt: asString(map['opens_at']) ?? '--:--',
      closesAt: asString(map['closes_at']) ?? '--:--',
      secondsLeft: seconds,
      deadline: (now ?? DateTime.now()).add(Duration(seconds: seconds)),
      nextChange: asString(map['next_change']),
      label: asString(map['label']),
    );
  }
}
