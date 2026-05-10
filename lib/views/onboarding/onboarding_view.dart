import 'package:flutter/material.dart';
import '../../services/onboarding_service.dart';
import '../auth/auth_wrapper.dart';

/// First-launch tour of CaratOne's headline features.
///
/// Shown only once per install — completion (Skip or Get Started) flips
/// the [OnboardingService] flag and forwards to [AuthWrapper].
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  static const _accent = Color(0xFF4F8AF4);
  static const _deepAccent = Color(0xFF1E3C72);

  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.receipt_long_rounded,
      iconBg: Color(0xFFE7EEFF),
      iconColor: _accent,
      title: 'Professional Invoices\nin Minutes',
      description:
          'Create GST-ready invoices with automatic CGST, SGST & IGST '
          'calculations, amount-in-words, and unlimited line items.',
    ),
    _OnboardingPageData(
      icon: Icons.inventory_2_rounded,
      iconBg: Color(0xFFEAF7EE),
      iconColor: Color(0xFF2E9E5B),
      title: 'Track Every Carat\nfrom Purchase to Sale',
      description:
          'Manage purchase lots, monitor remaining stock in real time, '
          'and create invoices straight from a purchase entry.',
    ),
    _OnboardingPageData(
      icon: Icons.account_balance_wallet_rounded,
      iconBg: Color(0xFFFFF3E0),
      iconColor: Color(0xFFEF8B2C),
      title: 'Master Your Books\nwith Smart Reports',
      description:
          'Record income, expenses and withdrawals. Get instant '
          'profit/loss insights and shareable PDF reports.',
    ),
    _OnboardingPageData(
      icon: Icons.cloud_sync_rounded,
      iconBg: Color(0xFFE9E1FB),
      iconColor: Color(0xFF6E4FE0),
      title: 'Securely Synced\nAcross Your Devices',
      description:
          'Powered by Firebase — your data is encrypted, backed up, and '
          'available wherever you sign in.',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  Future<void> _finishOnboarding() async {
    await OnboardingService.setOnboardingCompleted();
    if (!mounted) return;
    // Use an instant (zero-duration) transition so the loading dashboard
    // skeleton is never visible through the animation.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => const AuthWrapper(),
      ),
    );
  }

  void _onNextPressed() {
    if (_isLastPage) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackdrop(),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 12),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isLastPage ? 0 : 1,
                      child: TextButton(
                        onPressed: _isLastPage ? null : _finishOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: _deepAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) =>
                        _OnboardingPage(data: _pages[index]),
                  ),
                ),
                // Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 26 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? _accent
                              : _accent.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                ),
                // Action button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                        shadowColor: _accent.withOpacity(0.4),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Row(
                          key: ValueKey<bool>(_isLastPage),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLastPage ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _isLastPage
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.22),
              ),
            ),
          ),
          Positioned(
            top: 140,
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
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decorative illustration: layered halos around an icon.
          SizedBox(
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.iconColor.withOpacity(0.06),
                  ),
                ),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.iconColor.withOpacity(0.10),
                  ),
                ),
                Container(
                  width: 144,
                  height: 144,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.iconBg,
                    boxShadow: [
                      BoxShadow(
                        color: data.iconColor.withOpacity(0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Icon(
                    data.icon,
                    size: 72,
                    color: data.iconColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E3C72),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
