import 'dart:async';
import 'package:flutter/material.dart';
import 'package:invoice_generator/constants/app_translations.dart';
import '../../services/onboarding_service.dart';
import '../../services/localization_service.dart';
import '../auth/auth_wrapper.dart';
import '../onboarding/onboarding_view.dart';
import '../settings/language_selection_view.dart';


/// First screen the user sees on launch.
///
/// Shows the CaratOne logo + tagline for 3 seconds while we read the
/// onboarding flag, then routes to either [OnboardingView] (first install)
/// or [AuthWrapper] (returning user).
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF4F8AF4);
  static const _deepAccent = Color(0xFF1E3C72);
  static const _splashDuration = Duration(seconds: 3);

  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _fade;

  /// Started in [initState] so the prefs read happens *during* the splash
  /// animation, not after the timer fires. By the time we navigate away,
  /// this future is virtually always already resolved.
  late final Future<bool> _onboardingSeenFuture;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
    _onboardingSeenFuture = OnboardingService.isOnboardingCompleted();
    _scheduleNext();
  }

  void _scheduleNext() {
    Timer(_splashDuration, _goNext);
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    final seenOnboarding = await _onboardingSeenFuture;
    if (!mounted) return;

    final locService = LocalizationService.instance;
    final seenLanguage = locService.hasSeenSelection;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) {
          if (!seenLanguage) return const LanguageSelectionView();
          return seenOnboarding ? const AuthWrapper() : const OnboardingView();
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withOpacity(0.25),
                            blurRadius: 40,
                            spreadRadius: 4,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 76,
                        color: _accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fade,
                    child: Text(
                      'CaratOne'.tr,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: _deepAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _fade,
                    child: Text(
                      'Smart business management'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom progress indicator + branding. Use MediaQuery padding
          // so the content sits above the system gesture/nav bar on
          // devices that use one.
          Positioned(
            left: 0,
            right: 0,
            bottom: 36 + MediaQuery.of(context).padding.bottom,
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _accent.withOpacity(0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Made for jewelry & diamond traders'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE7EEFF),
            Color(0xFFF9FBFF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.22),
              ),
            ),
          ),
          Positioned(
            top: 160,
            left: -90,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _deepAccent.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
