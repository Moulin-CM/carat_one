import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has already seen the onboarding flow.
///
/// The flag is persisted in [SharedPreferences] so that onboarding only
/// shows on the very first launch after install. Tapping either the
/// "Skip" or "Get Started" button marks it complete.
class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';

  /// Returns `true` once the user has finished (or skipped) onboarding.
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Marks onboarding as seen so subsequent launches go straight to auth.
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Re-show onboarding on the next launch (handy for debugging / settings).
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
  }
}
