import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings_model.dart';

/// Per-user app settings persistence.
///
/// Cloud is the source of truth: read from `users/{uid}/settings` in
/// Realtime Database when authenticated, write through on every save.
/// SharedPreferences holds a per-user mirror so the UI keeps working
/// offline and during cold-start before the auth stream resolves.
///
/// One-shot migration: before this change settings were kept under a
/// global SharedPreferences key (`app_settings`). On the first
/// authenticated read after the migration, that legacy blob is promoted
/// into the user's cloud node so existing installs don't lose their
/// Stock Valuation, FY end, manual openings, etc.
class SettingsService {
  static const String _legacyKey = 'app_settings';
  static const String _localKeyPrefix = 'app_settings_';

  static String _localKey(String uid) => '$_localKeyPrefix$uid';

  static DatabaseReference _userRef(String uid) =>
      FirebaseDatabase.instance.ref('users/$uid/settings');

  /// Resolve the current user, waiting briefly for the auth stream to fire
  /// on cold start. Returns null if no user is signed in within the timeout
  /// — callers must fall back to local-only behavior in that case.
  static Future<User?> _getUser() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) return current;
    try {
      return await FirebaseAuth.instance
          .authStateChanges()
          .where((u) => u != null)
          .first
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _toStringKeyedMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (e) => MapEntry(e.key.toString(), _normalizeValue(e.value)),
        ),
      );
    }
    return <String, dynamic>{};
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value is Map) return _toStringKeyedMap(value);
    if (value is List) return value.map(_normalizeValue).toList();
    return value;
  }

  static Future<AppSettingsModel> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await _getUser();

    if (user == null) {
      // Pre-auth read (very early startup). Best effort: legacy global blob.
      return _decodeOrDefault(prefs.getString(_legacyKey));
    }

    final uid = user.uid;
    final perUserKey = _localKey(uid);

    // 1. Try cloud.
    try {
      final snapshot = await _userRef(uid).get();
      final value = snapshot.value;
      if (value is Map && value.isNotEmpty) {
        final normalized = _toStringKeyedMap(value);
        final encoded = jsonEncode(normalized);
        await prefs.setString(perUserKey, encoded);
        return AppSettingsModel.fromJson(normalized);
      }
    } catch (_) {
      // Network/permission failure — fall through to local cache.
    }

    // 2. Per-user local cache (offline or RTDB unreachable).
    final cached = prefs.getString(perUserKey);
    if (cached != null && cached.isNotEmpty) {
      return _decodeOrDefault(cached);
    }

    // 3. Legacy global blob from the pre-cloud installs. Promote it once
    // so subsequent devices for the same account see the same data.
    final legacy = prefs.getString(_legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      final model = _decodeOrDefault(legacy);
      await prefs.setString(perUserKey, legacy);
      try {
        await _userRef(uid).set(model.toJson());
      } catch (_) {}
      return model;
    }

    return AppSettingsModel();
  }

  static AppSettingsModel _decodeOrDefault(String? raw) {
    if (raw == null || raw.isEmpty) return AppSettingsModel();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettingsModel.fromJson(json);
    } catch (_) {
      return AppSettingsModel();
    }
  }

  static Future<void> saveSettings(AppSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final json = settings.toJson();
    final encoded = jsonEncode(json);

    final user = await _getUser();
    if (user == null) {
      // No auth yet — keep the legacy key as the last-resort store so the
      // value still survives a hot restart before sign-in completes.
      await prefs.setString(_legacyKey, encoded);
      return;
    }

    final uid = user.uid;
    await prefs.setString(_localKey(uid), encoded);
    try {
      await _userRef(uid).set(json);
    } catch (_) {
      // Cloud write failed (offline / permission). Local cache still holds
      // the latest value and will sync on the next successful save.
    }
  }

  static Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKey);
    final user = await _getUser();
    if (user != null) {
      final uid = user.uid;
      await prefs.remove(_localKey(uid));
      try {
        await _userRef(uid).remove();
      } catch (_) {}
    }
  }
}
