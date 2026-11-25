import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/json.dart';
import 'store_info.dart';

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(),
);

class StoredSession {
  const StoredSession({required this.storeKey, this.store});
  final String storeKey;
  final StoreInfo? store;
}

/// Keeps the `store_key` (and basic store info) in the phone's
/// secure storage (Android Keystore / iOS Keychain).
class SessionStorage {
  SessionStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _keyStoreKey = 'store_key';
  static const _keyStoreInfo = 'store_info';

  Future<StoredSession?> read() async {
    try {
      final key = await _storage.read(key: _keyStoreKey);
      if (key == null || key.isEmpty) return null;

      StoreInfo? store;
      final raw = await _storage.read(key: _keyStoreInfo);
      if (raw != null) {
        final map = asMap(jsonDecode(raw));
        if (map != null) store = StoreInfo.fromJson(map);
      }
      return StoredSession(storeKey: key, store: store);
    } catch (e) {
      // Unreadable storage (e.g. keystore reset after a backup restore):
      // start clean so the user can sign in again.
      debugPrint('SessionStorage.read failed: $e');
      await clear();
      return null;
    }
  }

  Future<void> write(String storeKey, StoreInfo? store) async {
    await _storage.write(key: _keyStoreKey, value: storeKey);
    if (store != null) {
      await saveStore(store);
    }
  }

  Future<void> saveStore(StoreInfo store) =>
      _storage.write(key: _keyStoreInfo, value: jsonEncode(store.toJson()));

  Future<void> clear() async {
    try {
      await _storage.delete(key: _keyStoreKey);
      await _storage.delete(key: _keyStoreInfo);
    } catch (e) {
      debugPrint('SessionStorage.clear failed: $e');
    }
  }
}
