import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` while the phone has a network connection (Wi-Fi / mobile / …).
/// It can't tell whether the internet behind it works — API errors still
/// cover that — but it catches airplane mode and "no signal".
final onlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool isOnline(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);

  try {
    yield isOnline(await connectivity.checkConnectivity());
  } catch (_) {
    yield true; // Unknown: don't show a false "offline" banner.
  }
  yield* connectivity.onConnectivityChanged.map(isOnline).distinct();
});
