import '../models/subscription_plan.dart';

class SubscriptionConstants {
  SubscriptionConstants._();

  // ── Google Play Console Product IDs ────────────────────────────────────────
  static const String starterProductId  = 'monthly_499';
  static const String proProductId      = 'pro_999';
  static const String businessProductId = 'business_1499';

  static const Set<String> allProductIds = {
    starterProductId,
    proProductId,
    businessProductId,
  };

  // Ordered list used for sorting the fetched product list
  static const List<String> orderedProductIds = [
    starterProductId,
    proProductId,
    businessProductId,
  ];

  static SubscriptionTier tierFromProductId(String productId) {
    switch (productId) {
      case starterProductId:
        return SubscriptionTier.starter;
      case proProductId:
        return SubscriptionTier.pro;
      case businessProductId:
        return SubscriptionTier.business;
      default:
        return SubscriptionTier.trial;
    }
  }

  static String? productIdFromTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return starterProductId;
      case SubscriptionTier.pro:
        return proProductId;
      case SubscriptionTier.business:
        return businessProductId;
      default:
        return null;
    }
  }
}
