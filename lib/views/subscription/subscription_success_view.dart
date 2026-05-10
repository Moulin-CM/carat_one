import 'package:flutter/material.dart';
import '../../models/subscription_plan.dart';
import '../../viewmodels/subscription_viewmodel.dart';

/// Full-screen animated success screen shown after a successful purchase
/// or restore. Pops itself and returns to the subscription plans view.
class SubscriptionSuccessView extends StatefulWidget {
  final bool   isRestore;
  final String planName;

  const SubscriptionSuccessView({
    super.key,
    required this.isRestore,
    required this.planName,
  });

  @override
  State<SubscriptionSuccessView> createState() =>
      _SubscriptionSuccessViewState();
}

class _SubscriptionSuccessViewState extends State<SubscriptionSuccessView>
    with TickerProviderStateMixin {
  late AnimationController _circleCtrl;
  late AnimationController _contentCtrl;
  late Animation<double>   _circleScale;
  late Animation<double>   _checkOpacity;
  late Animation<double>   _contentSlide;
  late Animation<double>   _contentOpacity;

  @override
  void initState() {
    super.initState();

    _circleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _circleScale = CurvedAnimation(
        parent: _circleCtrl, curve: Curves.elasticOut);
    _checkOpacity = CurvedAnimation(
        parent: _circleCtrl, curve: const Interval(0.4, 1.0));
    _contentSlide = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));
    _contentOpacity = CurvedAnimation(
        parent: _contentCtrl, curve: Curves.easeIn);

    Future.delayed(const Duration(milliseconds: 200), () {
      _circleCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _circleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  List<String> get _benefits {
    final tier = _tierFromName(widget.planName);
    return SubscriptionViewModel.benefitsForTier(tier);
  }

  SubscriptionTier _tierFromName(String name) {
    switch (name.toLowerCase()) {
      case 'starter': return SubscriptionTier.starter;
      case 'pro':     return SubscriptionTier.pro;
      case 'business':return SubscriptionTier.business;
      default:        return SubscriptionTier.trial;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              // ── Animated checkmark circle ──────────────────────────────────
              ScaleTransition(
                scale: _circleScale,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF48C8A8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: FadeTransition(
                    opacity: _checkOpacity,
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 60),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // ── Title & subtitle ────────────────────────────────────────────
              AnimatedBuilder(
                animation: _contentCtrl,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _contentSlide.value),
                  child: Opacity(opacity: _contentOpacity.value, child: child),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.isRestore
                          ? 'Subscription Restored!'
                          : '🎉 Welcome to ${widget.planName}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isRestore
                          ? 'Your previous subscription has been restored successfully.'
                          : 'Your plan is now active. Enjoy all the features below.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 15,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              // ── Benefits list ───────────────────────────────────────────────
              AnimatedBuilder(
                animation: _contentCtrl,
                builder: (context, child) => Opacity(
                    opacity: _contentOpacity.value, child: child),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: Column(
                    children: _benefits
                        .map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFF48C8A8), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(b,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14)),
                                ),
                              ]),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const Spacer(),
              // ── CTA button ──────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _contentCtrl,
                builder: (context, child) =>
                    Opacity(opacity: _contentOpacity.value, child: child),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Go to Dashboard',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
