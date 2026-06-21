import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-device toggle for the Modern UI experience.
///
/// Kept in SharedPreferences (not cloud-synced settings) because the
/// preferred presentation is a device-local choice — the same user may
/// want the modern look on their tablet and the classic dashboard on
/// their phone. Cheap to read, survives reinstall via Android backup.
class ModernUiService extends ChangeNotifier {
  static const String _prefsKey = 'modern_ui_enabled';

  bool _enabled = false;
  bool _initialized = false;

  bool get enabled => _enabled;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefsKey) ?? false;
    } catch (_) {
      _enabled = false;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {
      // Preference write failure is non-fatal — the in-memory value still
      // drives the UI for this session.
    }
  }
}
