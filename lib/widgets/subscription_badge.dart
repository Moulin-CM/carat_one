import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_translations.dart';
import '../models/subscription_plan.dart';
import '../viewmodels/subscription_viewmodel.dart';
import '../views/subscription/subscription_plans_view.dart';

enum SubscriptionBadgeSize { compact, large }

class _BadgeStyle {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final Color glow;

  const _BadgeStyle({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.glow,
  });
}

_BadgeStyle _styleFor(SubscriptionTier tier, {required bool isTrialActive}) {
  switch (tier) {
    case SubscriptionTier.trial:
      return _BadgeStyle(
        label: isTrialActive ? 'Free Trial'.tr : 'Free'.tr,
        icon: Icons.person_rounded,
        gradient: const [Color(0xFF8A94A6), Color(0xFFB0BAC9)],
        glow: const Color(0xFF8A94A6),
      );
    case SubscriptionTier.starter:
      return _BadgeStyle(
        label: 'Starter'.tr,
        icon: Icons.bolt_rounded,
        gradient: const [Color(0xFFB45309), Color(0xFFF59E0B)],
        glow: const Color(0xFFF59E0B),
      );
    case SubscriptionTier.pro:
      return _BadgeStyle(
        label: 'Pro'.tr,
        icon: Icons.star_rounded,
        gradient: const [Color(0xFF1E3C72), Color(0xFF4F8AF4)],
        glow: const Color(0xFF4F8AF4),
      );
    case SubscriptionTier.business:
      return _BadgeStyle(
        label: 'Business'.tr,
        icon: Icons.workspace_premium_rounded,
        gradient: const [Color(0xFF1A1033), Color(0xFF6B21A8), Color(0xFFD4AF37)],
        glow: const Color(0xFFD4AF37),
      );
    case SubscriptionTier.expired:
      return _BadgeStyle(
        label: 'Expired'.tr,
        icon: Icons.lock_rounded,
        gradient: const [Color(0xFF991B1B), Color(0xFFDC2626)],
        glow: const Color(0xFFDC2626),
      );
  }
}

class SubscriptionBadge extends StatelessWidget {
  final SubscriptionBadgeSize size;
  final bool onLightSurface;

  const SubscriptionBadge({
    super.key,
    this.size = SubscriptionBadgeSize.compact,
    this.onLightSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionViewModel>(
      builder: (context, vm, _) {
        final status = vm.status;
        final tier = status.plan;
        final isTrialActive =
            tier == SubscriptionTier.trial && status.isActive;
        final style = _styleFor(tier, isTrialActive: isTrialActive);

        return _BadgePill(
          style: style,
          size: size,
          onLightSurface: onLightSurface,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionPlansView()),
          ),
        );
      },
    );
  }
}

class _BadgePill extends StatelessWidget {
  final _BadgeStyle style;
  final SubscriptionBadgeSize size;
  final bool onLightSurface;
  final VoidCallback onTap;

  const _BadgePill({
    required this.style,
    required this.size,
    required this.onLightSurface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = size == SubscriptionBadgeSize.compact;

    final paddingH = isCompact ? 10.0 : 14.0;
    final paddingV = isCompact ? 6.0 : 8.0;
    final iconSize = isCompact ? 13.0 : 16.0;
    final textSize = isCompact ? 11.0 : 13.0;
    final radius = isCompact ? 14.0 : 20.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: style.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(onLightSurface ? 0.0 : 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: style.glow.withOpacity(0.35),
                blurRadius: isCompact ? 8 : 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.icon, color: Colors.white, size: iconSize),
              SizedBox(width: isCompact ? 5 : 7),
              Text(
                style.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: textSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
