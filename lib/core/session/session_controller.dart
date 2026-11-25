import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_storage.dart';
import 'store_info.dart';

enum SessionStatus { unknown, signedIn, signedOut }

@immutable
class SessionState {
  const SessionState._({
    required this.status,
    this.storeKey,
    this.store,
    this.expired = false,
  });

  /// Still reading the saved key at app start.
  const SessionState.unknown() : this._(status: SessionStatus.unknown);

  const SessionState.signedIn(String storeKey, StoreInfo? store)
    : this._(status: SessionStatus.signedIn, storeKey: storeKey, store: store);

  /// [expired] is true when the server rejected the key (401),
  /// so the sign-in screen can explain why the user is back there.
  const SessionState.signedOut({bool expired = false})
    : this._(status: SessionStatus.signedOut, expired: expired);

  final SessionStatus status;
  final String? storeKey;
  final StoreInfo? store;
  final bool expired;

  bool get isSignedIn => status == SessionStatus.signedIn;
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

/// Single source of truth for "who is signed in".
/// The router listens to it, and the API layer reads the key from it.
class SessionController extends Notifier<SessionState> {
  SessionStorage get _storage => ref.read(sessionStorageProvider);

  @override
  SessionState build() {
    Future.microtask(_restore);
    return const SessionState.unknown();
  }

  Future<void> _restore() async {
    final saved = await _storage.read();
    state = saved == null
        ? const SessionState.signedOut()
        : SessionState.signedIn(saved.storeKey, saved.store);
  }

  Future<void> signIn(String storeKey, StoreInfo? store) async {
    await _storage.write(storeKey, store);
    state = SessionState.signedIn(storeKey, store);
  }

  /// Keep the cached store name/phone fresh (from `/home` or `/profile`).
  Future<void> updateStore(StoreInfo store) async {
    final key = state.storeKey;
    if (!state.isSignedIn || key == null) return;
    state = SessionState.signedIn(key, store);
    await _storage.saveStore(store);
  }

  /// Clears the saved key. Safe to call more than once
  /// (several requests may fail with 401 at the same time).
  Future<void> signOut({bool expired = false}) async {
    if (state.status == SessionStatus.signedOut) return;
    state = SessionState.signedOut(expired: expired);
    await _storage.clear();
  }

  /// Phase 1 only: lets us browse the tab screens before sign-in exists.
  /// Nothing is saved. Removed in Phase 2.
  void debugPreview() {
    assert(kDebugMode);
    state = const SessionState.signedIn(
      'debug-preview',
      StoreInfo(name: 'Preview Store', phone: '01XXXXXXXXX'),
    );
  }
}
