import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

/// Profile + notifications. Reloads when a different store signs in.
final profileProvider = FutureProvider<ProfileData>((ref) async {
  ref.watch(sessionProvider.select((s) => s.storeKey));
  final data = await ref.read(profileRepositoryProvider).fetch();
  final store = data.store;
  if (store != null && store.name.isNotEmpty) {
    // Keep the cached store name/phone fresh.
    await ref.read(sessionProvider.notifier).updateStore(store);
  }
  return data;
});
