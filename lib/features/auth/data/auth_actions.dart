import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import 'auth_repository.dart';

/// Logs out: tells the server (best effort, in the background),
/// then clears the saved key. The router then shows Sign in.
Future<void> logOut(WidgetRef ref) async {
  unawaited(ref.read(authRepositoryProvider).logout());
  await ref.read(sessionProvider.notifier).signOut();
}
