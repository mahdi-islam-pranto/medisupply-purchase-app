import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../data/home_data.dart';
import '../data/home_repository.dart';

/// Home dashboard data. Reloads automatically when a different
/// store signs in; call `ref.refresh(homeProvider.future)` to reload.
final homeProvider = FutureProvider<HomeData>((ref) async {
  // Rebuild when the signed-in store changes (logout → another login).
  ref.watch(sessionProvider.select((s) => s.storeKey));

  final data = await ref.read(homeRepositoryProvider).fetch();

  // Keep the cached store name fresh for headers on other tabs.
  final store = data.store;
  if (store != null && ref.mounted) {
    await ref.read(sessionProvider.notifier).updateStore(store);
  }
  return data;
});
