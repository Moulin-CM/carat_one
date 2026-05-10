import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants/subscription_constants.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_status.dart';
import '../services/subscription_service.dart';

export '../services/subscription_service.dart' show SubPurchaseState;

class SubscriptionViewModel extends ChangeNotifier {
  final _service = SubscriptionService();
  final _subs = <StreamSubscription>[];

  // ── State ────────────────────────────────────────────────────────────────────
  SubPurchaseState _purchaseState = SubPurchaseState.idle;
  String?          _errorMessage;
  String?          _pendingProductId; // which card is showing a spinner

  SubPurchaseState get purchaseState    => _purchaseState;
  String?          get errorMessage     => _errorMessage;
  String?          get pendingProductId => _pendingProductId;

  // ── Forwarded getters ────────────────────────────────────────────────────────
  SubscriptionStatus   get status           => _service.currentStatus;
  List<ProductDetails> get availableProducts => _service.availableProducts;
  bool                 get storeAvailable    => _service.storeAvailable;

  // ── Convenience booleans ─────────────────────────────────────────────────────
  bool get isLoadingProducts => _purchaseState == SubPurchaseState.loadingProducts;
  bool get isPurchasePending => _purchaseState == SubPurchaseState.pending;
  bool get isRestoring       => _purchaseState == SubPurchaseState.restoring;
  bool get isPurchaseSuccess => _purchaseState == SubPurchaseState.success;
  bool get isPurchaseRestored=> _purchaseState == SubPurchaseState.restored;
  bool get isPurchaseFailed  =>
      _purchaseState == SubPurchaseState.error ||
      _purchaseState == SubPurchaseState.canceled;
  bool get hasPurchaseError  => _purchaseState == SubPurchaseState.error;
  bool get wasCanceled       => _purchaseState == SubPurchaseState.canceled;

  SubscriptionViewModel() {
    _subs.add(_service.statusStream.listen((_) => notifyListeners()));

    _subs.add(_service.purchaseStateStream.listen((state) {
      _purchaseState = state;
      if (state != SubPurchaseState.pending) _pendingProductId = null;
      notifyListeners();
    }));

    _subs.add(_service.errorStream.listen((msg) {
      _errorMessage = msg;
      notifyListeners();
    }));
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  Future<void> loadProducts() => _service.loadProducts();

  Future<void> buyPlan(ProductDetails product) async {
    _pendingProductId = product.id;
    notifyListeners();
    await _service.buyPlan(product);
  }

  Future<void> restorePurchases() => _service.restorePurchases();

  void clearPurchaseState() => _service.resetPurchaseState();

  // ── Helper: benefits list for a given tier ────────────────────────────────
  static List<String> benefitsForTier(SubscriptionTier tier) {
    for (final plan in SubscriptionPlan.plans) {
      if (plan.tier == tier) return plan.benefits;
    }
    return [];
  }

  /// The ProductDetails matching the user's currently active plan (if any).
  ProductDetails? get currentPlanProduct {
    final pid = SubscriptionConstants.productIdFromTier(status.plan);
    if (pid == null) return null;
    try {
      return availableProducts.firstWhere((p) => p.id == pid);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    for (final s in _subs) { s.cancel(); }
    super.dispose();
  }
}
