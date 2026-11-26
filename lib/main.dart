import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phone app: portrait only (also set in AndroidManifest / Info.plist).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ProviderScope(
      // Riverpod 3 retries failed providers on its own by default. We turn
      // that off: each screen shows the error with a "Try again" button.
      retry: (retryCount, error) => null,
      child: const StoreQuoteApp(),
    ),
  );
}
