import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';


class BillingService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseController.stream;

  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  void initialize() {
    _subscription = _iap.purchaseStream.listen(
      (purchases) => _purchaseController.add(purchases),
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('BillingService error: $error'),
    );
  }

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      _iap.queryProductDetails(ids);

  /// Initiates a new subscription purchase via Google Play.
  Future<bool> buySubscription(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Restores all previously purchased subscriptions.
  Future<void> restorePurchases() => _iap.restorePurchases();

  /// Acknowledge / complete a purchase so Google Play does not refund it.
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _purchaseController.close();
  }
}
