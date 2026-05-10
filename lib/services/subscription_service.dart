import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants/subscription_constants.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_status.dart';
import 'billing_service.dart';

/// UI-facing purchase lifecycle states.
enum SubPurchaseState {
  idle,
  loadingProducts,
  pending,   // Waiting for Google Play
  success,   // Purchase confirmed & delivered
  canceled,  // User dismissed the Play sheet
  error,     // Billing / network error
  restoring, // restorePurchases() in progress
  restored,  // One or more purchases restored
}

class SubscriptionService {
  final _db   = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  final _billing = BillingService();

  StreamSubscription? _purchaseSub;

  // ── Public streams ──────────────────────────────────────────────────────────
  final _statusCtrl        = StreamController<SubscriptionStatus>.broadcast();
  final _purchaseStateCtrl = StreamController<SubPurchaseState>.broadcast();
  final _errorCtrl         = StreamController<String?>.broadcast();

  Stream<SubscriptionStatus>  get statusStream       => _statusCtrl.stream;
  Stream<SubPurchaseState>    get purchaseStateStream => _purchaseStateCtrl.stream;
  Stream<String?>             get errorStream        => _errorCtrl.stream;

  // ── State ───────────────────────────────────────────────────────────────────
  SubscriptionStatus   _currentStatus    = SubscriptionStatus();
  List<ProductDetails> _availableProducts = [];
  bool                 _storeAvailable   = false;

  SubscriptionStatus   get currentStatus     => _currentStatus;
  List<ProductDetails> get availableProducts  => _availableProducts;
  bool                 get storeAvailable     => _storeAvailable;

  // ── Singleton ───────────────────────────────────────────────────────────────
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // ── Initialization ──────────────────────────────────────────────────────────
  Future<void> initialize() async {
    _billing.initialize();
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToFirebaseStatus(user.uid);
      } else {
        _currentStatus = SubscriptionStatus();
        _statusCtrl.add(_currentStatus);
      }
    });
    _purchaseSub =
        _billing.purchaseStream.listen(_handlePurchaseUpdates);
  }

  // ── Load live products from Play Store ──────────────────────────────────────
  Future<void> loadProducts() async {
    _purchaseStateCtrl.add(SubPurchaseState.loadingProducts);
    _errorCtrl.add(null);
    try {
      _storeAvailable = await _billing.isAvailable();
      if (!_storeAvailable) {
        _errorCtrl.add('Google Play Store is unavailable on this device.');
        _purchaseStateCtrl.add(SubPurchaseState.idle);
        return;
      }
      final response = await _billing
          .queryProductDetails(SubscriptionConstants.allProductIds);

      if (response.error != null) {
        _errorCtrl.add('Could not load plans: ${response.error!.message}');
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('⚠ Products not found in Play Console: '
            '${response.notFoundIDs}');
      }

      // Sort in canonical order: starter → pro → business
      final sorted = [...response.productDetails];
      sorted.sort((a, b) {
        final order = SubscriptionConstants.orderedProductIds;
        return order.indexOf(a.id).compareTo(order.indexOf(b.id));
      });
      _availableProducts = sorted;
    } catch (e) {
      _errorCtrl.add('Error loading plans: $e');
    } finally {
      _purchaseStateCtrl.add(SubPurchaseState.idle);
    }
  }

  // ── Firebase status listener ────────────────────────────────────────────────
  void _listenToFirebaseStatus(String uid) {
    _db.child('users/$uid/subscription').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data =
            Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        _currentStatus = SubscriptionStatus.fromMap(data);
      } else {
        _initializeTrial(uid);
      }
      _statusCtrl.add(_currentStatus);
    });
  }

  Future<void> _initializeTrial(String uid) async {
    final now = DateTime.now();
    final s = SubscriptionStatus(
      plan: SubscriptionTier.trial,
      trialStartedAt: now,
      trialEndsAt: now.add(const Duration(days: 7)),
    );
    await _db.child('users/$uid/subscription').set(s.toMap());
  }

  // ── Purchase & restore entry points ─────────────────────────────────────────
  Future<void> buyPlan(ProductDetails product) async {
    _purchaseStateCtrl.add(SubPurchaseState.pending);
    _errorCtrl.add(null);
    try {
      await _billing.buySubscription(product);
      // Result arrives via purchaseStream → _handlePurchaseUpdates
    } catch (e) {
      _purchaseStateCtrl.add(SubPurchaseState.error);
      _errorCtrl.add(e.toString());
    }
  }

  Future<void> restorePurchases() async {
    _purchaseStateCtrl.add(SubPurchaseState.restoring);
    _errorCtrl.add(null);
    try {
      await _billing.restorePurchases();
      // Restored items arrive via purchaseStream → _handlePurchaseUpdates
    } catch (e) {
      _purchaseStateCtrl.add(SubPurchaseState.error);
      _errorCtrl.add('Restore failed: $e');
    }
  }

  // ── Purchase stream handler ──────────────────────────────────────────────────
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      _processPurchase(p);
    }
  }

  Future<void> _processPurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        _purchaseStateCtrl.add(SubPurchaseState.pending);
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _deliverPurchase(purchase);
        _purchaseStateCtrl.add(
          purchase.status == PurchaseStatus.restored
              ? SubPurchaseState.restored
              : SubPurchaseState.success,
        );
        await _billing.completePurchase(purchase);
        break;

      case PurchaseStatus.canceled:
        _purchaseStateCtrl.add(SubPurchaseState.canceled);
        break;

      case PurchaseStatus.error:
        _purchaseStateCtrl.add(SubPurchaseState.error);
        _errorCtrl.add(
            purchase.error?.message ?? 'An unknown error occurred.');
        await _billing.completePurchase(purchase);
        break;
    }
  }

  Future<void> _deliverPurchase(PurchaseDetails purchase) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final tier = SubscriptionConstants.tierFromProductId(purchase.productID);
    final now  = DateTime.now();

    final newStatus = SubscriptionStatus(
      plan: tier,
      // Google manages actual renewals; we store +30 days as a soft expiry.
      expiryDate: now.add(const Duration(days: 30)),
      purchaseToken: purchase.purchaseID,
      lastVerifiedAt: now,
      autoRenewing: true,
    );

    await _db.child('users/$uid/subscription').update(newStatus.toMap());

    await _db.child('users/$uid/subscriptionHistory').push().set({
      'event':         purchase.status == PurchaseStatus.restored
                         ? 'restored' : 'subscribed',
      'plan':          tier.toString().split('.').last,
      'timestamp':     ServerValue.timestamp,
      'productId':     purchase.productID,
      'purchaseToken': purchase.purchaseID,
    });
  }

  // ── Reset state ──────────────────────────────────────────────────────────────
  void resetPurchaseState() {
    _purchaseStateCtrl.add(SubPurchaseState.idle);
    _errorCtrl.add(null);
  }

  void dispose() {
    _purchaseSub?.cancel();
    _statusCtrl.close();
    _purchaseStateCtrl.close();
    _errorCtrl.close();
  }
}
