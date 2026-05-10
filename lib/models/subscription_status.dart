import 'subscription_plan.dart';

class SubscriptionStatus {
  final SubscriptionTier plan;
  final DateTime? trialStartedAt;
  final DateTime? trialEndsAt;
  final DateTime? expiryDate;
  final bool autoRenewing;
  final String? purchaseToken;
  final String platform;
  final DateTime? lastVerifiedAt;

  SubscriptionStatus({
    this.plan = SubscriptionTier.trial,
    this.trialStartedAt,
    this.trialEndsAt,
    this.expiryDate,
    this.autoRenewing = false,
    this.purchaseToken,
    this.platform = 'android',
    this.lastVerifiedAt,
  });

  factory SubscriptionStatus.fromMap(Map<dynamic, dynamic> map) {
    return SubscriptionStatus(
      plan: SubscriptionTier.values.firstWhere(
        (e) => e.toString().split('.').last == (map['plan'] ?? 'trial'),
        orElse: () => SubscriptionTier.expired,
      ),
      trialStartedAt: map['trialStartedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['trialStartedAt'])
          : null,
      trialEndsAt: map['trialEndsAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['trialEndsAt'])
          : null,
      expiryDate: map['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'])
          : null,
      autoRenewing: map['autoRenewing'] ?? false,
      purchaseToken: map['purchaseToken'],
      platform: map['platform'] ?? 'android',
      lastVerifiedAt: map['lastVerifiedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastVerifiedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plan': plan.toString().split('.').last,
      'trialStartedAt': trialStartedAt?.millisecondsSinceEpoch,
      'trialEndsAt': trialEndsAt?.millisecondsSinceEpoch,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'autoRenewing': autoRenewing,
      'purchaseToken': purchaseToken,
      'platform': platform,
      'lastVerifiedAt': lastVerifiedAt?.millisecondsSinceEpoch,
    };
  }

  bool get isActive {
    if (plan == SubscriptionTier.expired) return false;
    final now = DateTime.now();
    if (plan == SubscriptionTier.trial) {
      return trialEndsAt == null || now.isBefore(trialEndsAt!);
    }
    return expiryDate == null || now.isBefore(expiryDate!);
  }

  bool get isProOrBusiness =>
      plan == SubscriptionTier.pro || plan == SubscriptionTier.business;
}
