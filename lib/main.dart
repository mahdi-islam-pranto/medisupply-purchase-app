import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      // Riverpod 3 retries failed providers on its own by default. We turn
      // that off: each screen shows the error with a "Try again" button.
      retry: (retryCount, error) => null,
      child: const StoreQuoteApp(),
    ),
  );
}
