import 'package:invoice_generator/constants/app_translations.dart';

enum SubscriptionTier {
  trial,
  starter,
  pro,
  business,
  expired,
}

class SubscriptionPlan {
  final SubscriptionTier tier;
  final String name;
  final String price;
  final double priceValue;
  final List<String> benefits;
  final bool isMostPopular;

  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.price,
    required this.priceValue,
    required this.benefits,
    this.isMostPopular = false,
  });

  static List<SubscriptionPlan> get plans => [
        SubscriptionPlan(
          tier: SubscriptionTier.starter,
          name: 'Starter',
          price: '₹499',
          priceValue: 499,
          isMostPopular: false,
          benefits: [
            '30 Purchases / month'.tr,
            '30 Sells / month'.tr,
            'Monthly Buy/Sell Reports'.tr,
            '10 PDF Prints / month'.tr,
            '5 Active Reminders'.tr,
            'JSON Export'.tr,
            '1 Device Sync'.tr,
          ],
        ),
        SubscriptionPlan(
          tier: SubscriptionTier.pro,
          name: 'Pro',
          price: '₹999',
          priceValue: 999,
          isMostPopular: true,
          benefits: [
            'Unlimited Purchases'.tr,
            'Unlimited Sells'.tr,
            'Full Period Reports'.tr,
            'Unlimited PDF Prints'.tr,
            'Unlimited Reminders'.tr,
            'Export & Import'.tr,
            '2 Device Sync'.tr,
            'No Ads'.tr,
          ],
        ),
        SubscriptionPlan(
          tier: SubscriptionTier.business,
          name: 'Business',
          price: '₹1,499',
          priceValue: 1499,
          isMostPopular: false,
          benefits: [
            'Everything in Pro'.tr,
            'Unlimited Device Sync'.tr,
            'Brokerage Reports'.tr,
            'Priority Support'.tr,
            'Multi-user Access (Coming Soon)'.tr,
          ],
        ),
      ];
}
