import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../models/subscription_plan.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../constants/app_translations.dart';
import 'subscription_success_view.dart';

/// Modern UI surface for the Subscription Plans screen.
///
/// Same `SubscriptionViewModel`, same `loadProducts` / `buyPlan` /
/// `restorePurchases` flows, same success / error / cancel state
/// handling. Only the visual layer is restyled to the website's
/// navy + blue→cyan→violet palette.
class ModernSubscriptionPlansView extends StatefulWidget {
  const ModernSubscriptionPlansView({super.key});

  @override
  State<ModernSubscriptionPlansView> createState() =>
      _ModernSubscriptionPlansViewState();
}

class _ModernSubscriptionPlansViewState
    extends State<ModernSubscriptionPlansView> {
  // Website tokens
  static const _bg0 = Color(0xFF07091C);
  static const _bg1 = Color(0xFF0C1230);
  static const _primary = Color(0xFF4F8AF4);
  static const _accent = Color(0xFF38BDF8);
  static const _violet = Color(0xFFA78BFA);

  static const _grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primary, _accent, _violet],
    stops: [0.0, 0.5, 1.0],
  );

  bool _successNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionViewModel>().loadProducts();
    });
  }

  void _handleStateChange(SubscriptionViewModel vm) {
    if ((vm.isPurchaseSuccess || vm.isPurchaseRestored) &&
        !_successNavigated) {
      _successNavigated = true;
      final planName = _resolvePlanName(vm);
      Navigator.of(context)
          .push(MaterialPageRoute(
        builder: (_) => SubscriptionSuccessView(
          isRestore: vm.isPurchaseRestored,
          planName: planName,
        ),
      ))
          .then((_) {
        vm.clearPurchaseState();
        _successNavigated = false;
      });
    }

    if (vm.hasPurchaseError) {
      _showErrorSnackbar(vm.errorMessage ?? 'An error occurred.'.tr);
      vm.clearPurchaseState();
    }

    if (vm.wasCanceled) {
      vm.clearPurchaseState();
    }
  }

  String _resolvePlanName(SubscriptionViewModel vm) {
    for (final plan in SubscriptionPlan.plans) {
      if (vm.status.plan == plan.tier) return plan.name;
    }
    return vm.status.plan.toString().split('.').last;
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _productIdForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return 'monthly_499';
      case SubscriptionTier.pro:
        return 'pro_999';
      case SubscriptionTier.business:
        return 'business_1499';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionViewModel>(
      builder: (context, vm, _) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _handleStateChange(vm));

        return Scaffold(
          backgroundColor: _bg0,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(vm),
          body: Stack(
            children: [
              _buildBackdrop(),
              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      if (!vm.storeAvailable && !vm.isLoadingProducts)
                        _buildStoreUnavailable(vm)
                      else
                        _buildPlansList(vm),
                      const SizedBox(height: 20),
                      _buildFooter(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────  APP BAR  ────────────────────────────────

  PreferredSizeWidget _buildAppBar(SubscriptionViewModel vm) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
        ).createShader(rect),
        child: Text(
          'Choose Your Plan'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: vm.isRestoring || vm.isPurchasePending
              ? null
              : () => vm.restorePurchases(),
          child: vm.isRestoring
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accent),
                )
              : Text(
                  'Restore'.tr,
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─────────────────────────────  BACKDROP  ───────────────────────────────

  Widget _buildBackdrop() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bg1, _bg0],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _glow(280, _primary.withOpacity(0.28)),
          ),
          Positioned(
            top: 240,
            left: -100,
            child: _glow(240, _violet.withOpacity(0.20)),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }

  // ─────────────────────────────  HEADER  ─────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _grad,
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.45),
                  blurRadius: 26,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: _violet.withOpacity(0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 18),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
            ).createShader(rect),
            child: Text(
              'Unlock Full Power'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the plan that fits your business'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────  PLANS LIST  ─────────────────────────────

  Widget _buildPlansList(SubscriptionViewModel vm) {
    if (vm.isLoadingProducts) {
      return _buildShimmerList();
    }

    if (vm.availableProducts.isEmpty) {
      return _buildEmptyState(vm);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: SubscriptionPlan.plans.map((plan) {
          ProductDetails? product;
          try {
            product = vm.availableProducts.firstWhere(
              (p) => p.id == _productIdForTier(plan.tier),
            );
          } catch (_) {
            product = null;
          }
          return _ModernPlanCard(plan: plan, product: product, vm: vm);
        }).toList(),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(3, (_) => const _ModernShimmerCard()),
      ),
    );
  }

  Widget _buildEmptyState(SubscriptionViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Icon(Icons.cloud_off_rounded,
                color: Colors.white.withOpacity(0.45), size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'Plans could not be loaded'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              vm.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _outlinedAccentButton(
            label: 'Retry'.tr,
            icon: Icons.refresh_rounded,
            onTap: () => vm.loadProducts(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreUnavailable(SubscriptionViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Icon(Icons.store_mall_directory_outlined,
                color: Colors.white.withOpacity(0.45), size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'Google Play Store unavailable'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure you are connected to the internet and have a Google account set up.'
                .tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          _outlinedAccentButton(
            label: 'Try Again'.tr,
            icon: Icons.refresh_rounded,
            onTap: () => vm.loadProducts(),
          ),
        ],
      ),
    );
  }

  Widget _outlinedAccentButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withOpacity(0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _accent, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────  FOOTER  ─────────────────────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Subscriptions auto-renew monthly. Cancel anytime in Google Play Store.\nPrices shown are set by your Play Console configuration.'
            .tr,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 11,
          height: 1.6,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                          PLAN CARD (Modern)
// ─────────────────────────────────────────────────────────────────────────────

class _ModernPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final ProductDetails? product;
  final SubscriptionViewModel vm;

  const _ModernPlanCard({
    required this.plan,
    required this.product,
    required this.vm,
  });

  static const _primary = Color(0xFF4F8AF4);
  static const _accent = Color(0xFF38BDF8);
  static const _violet = Color(0xFFA78BFA);
  static const _emerald = Color(0xFF34D399);
  static const _gold = Color(0xFFFBBF24);

  static const _grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primary, _accent, _violet],
    stops: [0.0, 0.5, 1.0],
  );

  bool get _isCurrent => vm.status.plan == plan.tier;
  bool get _isPending =>
      vm.isPurchasePending && vm.pendingProductId == product?.id;

  Color get _tierColor {
    switch (plan.tier) {
      case SubscriptionTier.starter:
        return _emerald;
      case SubscriptionTier.pro:
        return _accent;
      case SubscriptionTier.business:
        return _gold;
      default:
        return _accent;
    }
  }

  IconData get _tierIcon {
    switch (plan.tier) {
      case SubscriptionTier.starter:
        return Icons.bolt_rounded;
      case SubscriptionTier.pro:
        return Icons.workspace_premium_rounded;
      case SubscriptionTier.business:
        return Icons.diamond_rounded;
      default:
        return Icons.star;
    }
  }

  List<Color> get _tierGradient {
    switch (plan.tier) {
      case SubscriptionTier.starter:
        return const [Color(0xFF10B981), Color(0xFF34D399)];
      case SubscriptionTier.pro:
        return const [_primary, _accent];
      case SubscriptionTier.business:
        return const [Color(0xFFFBBF24), Color(0xFFF59E0B)];
      default:
        return const [_primary, _accent];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPopular = plan.isMostPopular;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: isPopular
            ? const LinearGradient(
                colors: [
                  Color(0xFF111A38),
                  Color(0xFF132149),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPopular ? null : Colors.white.withOpacity(0.04),
        border: Border.all(
          color: isPopular
              ? _accent.withOpacity(0.50)
              : Colors.white.withOpacity(0.10),
          width: isPopular ? 1.5 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: _accent.withOpacity(0.25),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: _violet.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular) const SizedBox(height: 12),
                _buildHeader(),
                const SizedBox(height: 6),
                _buildPrice(),
                const SizedBox(height: 18),
                Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 14),
                ...plan.benefits.map((b) => _benefitRow(b)),
                const SizedBox(height: 18),
                _buildButton(context),
              ],
            ),
          ),
          if (isPopular) _buildPopularBadge(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _tierGradient,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _tierGradient.first.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(_tierIcon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            plan.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (_isCurrent) ...[
          const SizedBox(width: 8),
          _buildCurrentBadge(),
        ],
      ],
    );
  }

  Widget _buildPrice() {
    final displayPrice = product?.price ?? plan.price;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            colors: plan.isMostPopular
                ? const [_primary, _accent, _violet]
                : [_tierColor, _tierColor],
          ).createShader(rect),
          child: Text(
            displayPrice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '/ month'.tr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _benefitRow(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _emerald.withOpacity(0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 13),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              benefit.tr,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    if (_isCurrent) {
      return SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _emerald.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _emerald.withOpacity(0.45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: _emerald, size: 18),
              const SizedBox(width: 8),
              Text(
                'Current Plan'.tr,
                style: const TextStyle(
                  color: _emerald,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final canPurchase = product != null && !vm.isPurchasePending;
    final isPopular = plan.isMostPopular;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canPurchase ? () => vm.buyPlan(product!) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: canPurchase
                  ? (isPopular
                      ? _grad
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _tierGradient,
                        ))
                  : null,
              color: canPurchase
                  ? null
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              boxShadow: canPurchase
                  ? [
                      BoxShadow(
                        color: (isPopular
                                ? _accent
                                : _tierGradient.first)
                            .withOpacity(0.40),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: _isPending
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    ),
                  )
                : Center(
                    child: Text(
                      product == null
                          ? 'Unavailable'.tr
                          : 'Get Started'.tr,
                      style: TextStyle(
                        color: canPurchase
                            ? Colors.white
                            : Colors.white.withOpacity(0.45),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularBadge() {
    return Positioned(
      top: 0,
      right: 20,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          gradient: _grad,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'MOST POPULAR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _emerald.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _emerald.withOpacity(0.50), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: _emerald, size: 12),
          const SizedBox(width: 4),
          Text(
            'Active'.tr,
            style: const TextStyle(
              color: _emerald,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//                          SHIMMER CARD (Modern)
// ─────────────────────────────────────────────────────────────────────────────

class _ModernShimmerCard extends StatelessWidget {
  const _ModernShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A2238),
      highlightColor: const Color(0xFF2A3052),
      period: const Duration(milliseconds: 1400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 260,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2238),
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}
