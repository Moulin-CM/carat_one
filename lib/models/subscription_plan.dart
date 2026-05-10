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
        const SubscriptionPlan(
          tier: SubscriptionTier.starter,
          name: 'Starter',
          price: '₹499',
          priceValue: 499,
          isMostPopular: false,
          benefits: [
            '30 Purchases / month',
            '30 Sells / month',
            'Monthly Buy/Sell Reports',
            '10 PDF Prints / month',
            '5 Active Reminders',
            'JSON Export',
            '1 Device Sync',
          ],
        ),
        const SubscriptionPlan(
          tier: SubscriptionTier.pro,
          name: 'Pro',
          price: '₹999',
          priceValue: 999,
          isMostPopular: true,
          benefits: [
            'Unlimited Purchases',
            'Unlimited Sells',
            'Full Period Reports',
            'Unlimited PDF Prints',
            'Unlimited Reminders',
            'Export & Import',
            '2 Device Sync',
            'No Ads',
          ],
        ),
        const SubscriptionPlan(
          tier: SubscriptionTier.business,
          name: 'Business',
          price: '₹1,499',
          priceValue: 1499,
          isMostPopular: false,
          benefits: [
            'Everything in Pro',
            'Unlimited Device Sync',
            'Brokerage Reports',
            'Priority Support',
            'Multi-user Access (Coming Soon)',
          ],
        ),
      ];
}
