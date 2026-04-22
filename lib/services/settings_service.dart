import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings_model.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';

  static Future<AppSettingsModel> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null && settingsJson.isNotEmpty) {
      try {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        return AppSettingsModel.fromJson(json);
      } catch (_) {
        // If parsing fails, return default settings
        return AppSettingsModel();
      }
    }

    return AppSettingsModel();
  }

  static Future<void> saveSettings(AppSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, settingsJson);
  }

  static Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }
}

