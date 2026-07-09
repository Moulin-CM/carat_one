import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Writes lightweight product-analytics events to Firebase Realtime
/// Database at `/analytics/{yyyy-MM-dd}/{pushId}` so the Web admin
/// panel can render weekly performance reports without needing a
/// paid Firebase Analytics + BigQuery pipeline.
///
/// Event shape:
///   { type: 'install'|'session_start'|'session_end'|'feature'|'crash'|'purchase',
///     uid: '<user uid or null>',
///     at:  <ms since epoch>,
///     extras: { ...arbitrary payload } }
///
/// Fire-and-forget — every method swallows errors so the mobile UX is
/// never blocked by analytics writes.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const String _kFirstRunKey = 'analytics:firstRunLogged';
  static const String _kInstalledVersionKey = 'analytics:installedVersion';
  static const String _kSessionStartKey = 'analytics:sessionStartMs';

  DatabaseReference get _root => FirebaseDatabase.instance.ref('analytics');
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Call once at app startup (after Firebase.initializeApp). Fires an
  /// `install` event on first launch of each new build, then a
  /// `session_start` event every launch.
  Future<void> initialize() async {
    // Never block startup — everything below is best-effort.
    try {
      final prefs = await SharedPreferences.getInstance();
      final info = await PackageInfo.fromPlatform();
      final currentVersion = '${info.version}+${info.buildNumber}';

      final firstRunLogged = prefs.getBool(_kFirstRunKey) ?? false;
      final installedVersion = prefs.getString(_kInstalledVersionKey);

      if (!firstRunLogged) {
        // Very first launch on this device.
        await _log('install', extras: {
          'version': currentVersion,
          'platform': _platform(),
          'first': true,
        });
        await prefs.setBool(_kFirstRunKey, true);
        await prefs.setString(_kInstalledVersionKey, currentVersion);
      } else if (installedVersion != null && installedVersion != currentVersion) {
        // Fresh install of a new build (upgrade).
        await _log('install', extras: {
          'version': currentVersion,
          'previous': installedVersion,
          'platform': _platform(),
          'upgrade': true,
        });
        await prefs.setString(_kInstalledVersionKey, currentVersion);
      }

      // Session start marker
      await prefs.setInt(_kSessionStartKey, DateTime.now().millisecondsSinceEpoch);
      await _log('session_start', extras: {
        'version': currentVersion,
        'platform': _platform(),
      });
    } catch (e) {
      debugPrint('AnalyticsService init failed: $e');
    }
  }

  /// Call from lifecycle observer when the app goes to background.
  Future<void> logSessionEnd() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startMs = prefs.getInt(_kSessionStartKey);
      if (startMs == null) return;
      final durationSec = ((DateTime.now().millisecondsSinceEpoch - startMs) / 1000).round();
      await _log('session_end', extras: {'duration': durationSec});
    } catch (e) {
      debugPrint('AnalyticsService logSessionEnd failed: $e');
    }
  }

  /// Record a feature interaction (e.g. "invoice_create", "pdf_export").
  Future<void> logFeature(String name, {Map<String, Object?>? extras}) async {
    await _log('feature', extras: {'name': name, ...?extras});
  }

  /// Record a crash — call from FlutterError.onError / PlatformDispatcher.
  Future<void> logCrash(String message, {String? stack}) async {
    await _log('crash', extras: {
      'message': message,
      if (stack != null) 'stack': stack.substring(0, stack.length.clamp(0, 2000)),
      'platform': _platform(),
    });
  }

  /// Record a successful in-app purchase.
  Future<void> logPurchase({
    required String productId,
    required num amount,
    String currency = 'INR',
  }) async {
    await _log('purchase', extras: {
      'productId': productId,
      'amount': amount,
      'currency': currency,
    });
  }

  // ---------------------------------------------------------------
  Future<void> _log(String type, {Map<String, Object?>? extras}) async {
    try {
      final now = DateTime.now();
      final dayKey = '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      await _root.child(dayKey).push().set({
        'type': type,
        'uid': _uid,
        'at': now.millisecondsSinceEpoch,
        if (extras != null && extras.isNotEmpty) 'extras': _stripNulls(extras),
      });
    } catch (e) {
      debugPrint('AnalyticsService _log($type) failed: $e');
    }
  }

  Map<String, Object?> _stripNulls(Map<String, Object?> src) {
    return {
      for (final e in src.entries)
        if (e.value != null) e.key: e.value,
    };
  }

  String _platform() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
