import 'package:flutter/material.dart';
import 'package:invoice_generator/constants/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';


class LocalizationService extends ChangeNotifier {
  static const String _langKey = 'selected_language';
  static const String _seenKey = 'language_selection_seen';

  String _currentLanguage = 'en';
  bool _hasSeenSelection = false;

  String get currentLanguage => _currentLanguage;
  bool get hasSeenSelection => _hasSeenSelection;

  static LocalizationService? _instance;
  static LocalizationService get instance => _instance!;
  static LocalizationService? get instanceOrNull => _instance;

  LocalizationService() {
    _instance = this;
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_langKey) ?? 'en';
    _hasSeenSelection = prefs.getBool(_seenKey) ?? false;

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _syncWithUser(user.uid);
      }
    });
  }

  Future<void> setLanguage(String langCode, {bool notify = true}) async {
    if (_currentLanguage == langCode) return;

    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, langCode);
    
    if (notify) {
      notifyListeners();
    }

    // Push to Firebase if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final ref = FirebaseDatabase.instance.ref().child('users'.tr).child(user.uid);
        await ref.update({'language'.tr: langCode});
      } catch (e) {
        debugPrint('Failed to sync language to Firebase: $e');
      }
    }
  }

  Future<void> markSelectionSeen() async {
    _hasSeenSelection = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  /// Syncs language with Firebase. Call this when a user logs in.
  void _syncWithUser(String uid) {
    final ref = FirebaseDatabase.instance.ref().child('users'.tr).child(uid).child('language'.tr);
    
    // First, push our current language to Firebase to ensure consistency if it was just changed
    ref.set(_currentLanguage).then((_) {
      // Then listen for future changes from other devices
      ref.onValue.listen((event) async {
        final val = event.snapshot.value;
        if (val != null && val is String) {
          if (val != _currentLanguage) {
            _currentLanguage = val;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_langKey, val);
            notifyListeners();
          }
        }
      });
    }).catchError((e) {
      debugPrint('Failed to initialize language sync: $e');
    });
  }
}
