import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has opted into the Modern UI pilot.
///
/// Persisted in SharedPreferences so the choice survives restarts. The
/// classic UI is the default; the modern surface is rendered only when
/// [enabled] is true.
class ModernUiService extends ChangeNotifier {
  static const String _key = 'modern_ui_enabled';

  bool _enabled = false;

  bool get enabled => _enabled;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (e) {
      debugPrint('ModernUiService: failed to persist toggle: $e');
    }
  }
}
