import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../models/subscription_plan.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import 'subscription_success_view.dart';
import '../../constants/app_translations.dart';


class SubscriptionPlansView extends StatefulWidget {
  const SubscriptionPlansView({super.key});

  @override
  State<SubscriptionPlansView> createState() => _SubscriptionPlansViewState();
}

class _SubscriptionPlansViewState extends State<SubscriptionPlansView> {
  bool _successNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionViewModel>().loadProducts();
    });
  }

  void _handleStateChange(SubscriptionViewModel vm) {
    if ((vm.isPurchaseSuccess || vm.isPurchaseRestored) && !_successNavigated) {
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
    // Match the current status tier to a plan name
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

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionViewModel>(
      builder: (context, vm, _) {
        // Side-effect: navigate on state change
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _handleStateChange(vm));

        return Scaffold(
          backgroundColor: const Color(0xFF0F0E1A),
          appBar: _buildAppBar(vm),
          body: _buildBody(vm),
        );
      },
    );
  }

  AppBar _buildAppBar(SubscriptionViewModel vm) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Choose Your Plan'.tr,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
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
                      strokeWidth: 2, color: Color(0xFF6C63FF)),
                )
              : Text(
                  'Restore'.tr,
                  style: const TextStyle(
                      color: Color(0xFF6C63FF), fontWeight: FontWeight.w600),
                ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(SubscriptionViewModel vm) {
    return SingleChildScrollView(
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
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1830), Color(0xFF0F0E1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF48C8A8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock Full Power'.tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the plan that fits your business'.tr,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }

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
          // Find the matching live product from Play Store
          ProductDetails? product;
          try {
            product = vm.availableProducts.firstWhere(
              (p) => p.id == _productIdForTier(plan.tier),
            );
          } catch (_) {
            product = null;
          }
          return _PlanCard(
            plan: plan,
            product: product,
            vm: vm,
          );
        }).toList(),
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

  Widget _buildShimmerList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(3, (_) => _ShimmerCard()),
      ),
    );
  }

  Widget _buildEmptyState(SubscriptionViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded,
              color: Colors.white.withValues(alpha: 0.3), size: 60),
          const SizedBox(height: 16),
          Text(
            'Plans could not be loaded'.tr,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              vm.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => vm.loadProducts(),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6C63FF)),
            label: Text('Retry'.tr,
                style: const TextStyle(color: Color(0xFF6C63FF))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6C63FF)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
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
          Icon(Icons.store_mall_directory_outlined,
              color: Colors.white.withValues(alpha: 0.3), size: 60),
          const SizedBox(height: 16),
          Text('Google Play Store unavailable'.tr,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Make sure you are connected to the internet and have a Google account set up.'.tr
                .tr,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => vm.loadProducts(),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6C63FF)),
            label: Text('Try Again'.tr,
                style: const TextStyle(color: Color(0xFF6C63FF))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6C63FF)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Subscriptions auto-renew monthly. Cancel anytime in Google Play Store.\nPrices shown are set by your Play Console configuration.'
            .tr,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 11,
            height: 1.6),
      ),
    );
  }
}

// ── Plan Card ─────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final ProductDetails? product;
  final SubscriptionViewModel vm;

  const _PlanCard({
    required this.plan,
    required this.product,
    required this.vm,
  });

  bool get _isCurrent => vm.status.plan == plan.tier;
  bool get _isPending =>
      vm.isPurchasePending && vm.pendingProductId == product?.id;

  @override
  Widget build(BuildContext context) {
    final isPopular = plan.isMostPopular;
    final borderColor = isPopular
        ? const Color(0xFF6C63FF)
        : Colors.white.withValues(alpha: 0.12);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isPopular
            ? const LinearGradient(
                colors: [Color(0xFF1E1B3A), Color(0xFF1A2240)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPopular ? null : const Color(0xFF1A1830),
        border: Border.all(color: borderColor, width: isPopular ? 1.5 : 1),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
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
                if (isPopular) const SizedBox(height: 8), // space for badge
                _buildHeader(),
                const SizedBox(height: 4),
                _buildPrice(),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF2A2845), height: 1),
                const SizedBox(height: 16),
                ...plan.benefits.map((b) => _BenefitRow(benefit: b)),
                const SizedBox(height: 20),
                _buildButton(context),
              ],
            ),
          ),
          if (isPopular) _buildPopularBadge(),
          if (_isCurrent) _buildCurrentBadge(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _tierIcon(),
        const SizedBox(width: 10),
        Text(
          plan.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _tierIcon() {
    IconData icon;
    Color color;
    switch (plan.tier) {
      case SubscriptionTier.starter:
        icon = Icons.bolt_rounded;
        color = const Color(0xFF48C8A8);
        break;
      case SubscriptionTier.pro:
        icon = Icons.workspace_premium_rounded;
        color = const Color(0xFF6C63FF);
        break;
      case SubscriptionTier.business:
        icon = Icons.diamond_rounded;
        color = const Color(0xFFFFD700);
        break;
      default:
        icon = Icons.star;
        color = Colors.grey;
    }
    return Icon(icon, color: color, size: 22);
  }

  Widget _buildPrice() {
    // Prefer live Play Store price; fall back to static price
    final displayPrice = product?.price ?? plan.price;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          displayPrice,
          style: TextStyle(
            color: plan.isMostPopular
                ? const Color(0xFF6C63FF)
                : const Color(0xFF48C8A8),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '/ month'.tr,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context) {
    if (_isCurrent) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_rounded,
              color: Color(0xFF48C8A8), size: 18),
          label: Text('Current Plan'.tr,
              style: const TextStyle(color: Color(0xFF48C8A8))),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF48C8A8)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    final canPurchase = product != null && !vm.isPurchasePending;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canPurchase ? () => vm.buyPlan(product!) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: plan.isMostPopular
              ? const Color(0xFF6C63FF)
              : const Color(0xFF2A2845),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF2A2845).withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: plan.isMostPopular ? 4 : 0,
          shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isPending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                product == null ? 'Unavailable'.tr : 'Get Started'.tr,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
      ),
    );
  }

  Widget _buildPopularBadge() {
    return Positioned(
      top: 0,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: const BoxDecoration(
          gradient:
              LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF48C8A8)]),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        child: Text(
          'MOST POPULAR'.tr,
          style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildCurrentBadge() {
    return Positioned(
      top: 12,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF48C8A8).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF48C8A8).withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF48C8A8), size: 12),
            const SizedBox(width: 4),
            Text('Active'.tr,
                style: const TextStyle(
                    color: Color(0xFF48C8A8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Benefit Row ───────────────────────────────────────────────────────────────
class _BenefitRow extends StatelessWidget {
  final String benefit;
  const _BenefitRow({required this.benefit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF48C8A8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              benefit.tr,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer Placeholder Card ──────────────────────────────────────────────────
class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1830),
      highlightColor: const Color(0xFF2A2845),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 260,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1830),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
