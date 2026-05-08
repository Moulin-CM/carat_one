import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Central AdMob service.
///
/// Responsibilities:
///  * One-shot SDK initialization (idempotent — safe to call repeatedly).
///  * Single source of truth for ad-unit IDs (test vs production, per platform).
///  * Pre-loads and recycles a single interstitial / rewarded ad so the user
///    never waits at the moment of display.
///  * Enforces an interstitial frequency cap to stay AdMob-policy-compliant
///    (no back-to-back full-screen ads, no ads on app launch).
///
/// Usage:
///   await AdsService.instance.initialize();
///   AdsService.instance.maybeShowInterstitial();
///   AdsService.instance.showRewarded(onReward: () { ... });
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  /// Flip to `false` once you have real AdMob ad-unit IDs and are ready to ship.
  /// While `true` we always serve Google's official test ads — required by AdMob
  /// policy during development; clicking your own real ads is a ban-able offense.
  static const bool useTestAds = true;

  // ---------------------------------------------------------------------------
  // Test ad-unit IDs (safe — published by Google for development).
  // https://developers.google.com/admob/flutter/test-ads
  // ---------------------------------------------------------------------------
  static const _testBannerAndroid       = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos           = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos     = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid     = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos         = 'ca-app-pub-3940256099942544/1712485313';
  static const _testNativeAndroid       = 'ca-app-pub-3940256099942544/2247696110';
  static const _testNativeIos           = 'ca-app-pub-3940256099942544/3986624511';

  // ---------------------------------------------------------------------------
  // TODO(production): replace these with your own ad units from
  //   https://apps.admob.com/  →  Apps  →  Ad units
  // Keep separate units per format per platform.
  // ---------------------------------------------------------------------------
  static const _prodBannerAndroid       = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _prodBannerIos           = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _prodInterstitialAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _prodInterstitialIos     = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _prodRewardedAndroid     = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _prodRewardedIos         = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _prodNativeAndroid       = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _prodNativeIos           = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  bool _initialized = false;
  Future<void>? _initFuture;

  // Interstitial state.
  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  DateTime? _lastInterstitialShownAt;

  /// Minimum gap between interstitials. Keeps user experience tolerable AND
  /// keeps us safely on the right side of AdMob's "ad density" policy.
  static const Duration _interstitialMinGap = Duration(seconds: 90);

  // Rewarded state.
  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;

  // ---------------------------------------------------------------------------
  // Platform support.
  // AdMob currently only supports Android & iOS. Everything is a no-op on
  // web / desktop so the app keeps working there.
  // ---------------------------------------------------------------------------
  bool get isSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Ad unit accessors
  // ---------------------------------------------------------------------------
  String get bannerAdUnitId {
    if (!isSupported) return '';
    if (useTestAds) {
      return Platform.isAndroid ? _testBannerAndroid : _testBannerIos;
    }
    return Platform.isAndroid ? _prodBannerAndroid : _prodBannerIos;
  }

  String get interstitialAdUnitId {
    if (!isSupported) return '';
    if (useTestAds) {
      return Platform.isAndroid ? _testInterstitialAndroid : _testInterstitialIos;
    }
    return Platform.isAndroid ? _prodInterstitialAndroid : _prodInterstitialIos;
  }

  String get rewardedAdUnitId {
    if (!isSupported) return '';
    if (useTestAds) {
      return Platform.isAndroid ? _testRewardedAndroid : _testRewardedIos;
    }
    return Platform.isAndroid ? _prodRewardedAndroid : _prodRewardedIos;
  }

  String get nativeAdUnitId {
    if (!isSupported) return '';
    if (useTestAds) {
      return Platform.isAndroid ? _testNativeAndroid : _testNativeIos;
    }
    return Platform.isAndroid ? _prodNativeAndroid : _prodNativeIos;
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  Future<void> initialize() {
    if (!isSupported) return Future.value();
    if (_initialized) return Future.value();
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      // Eagerly preload the next interstitial / rewarded so the first call is
      // instant. Both swallow their own errors.
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('AdsService: initialization failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Interstitial
  // ---------------------------------------------------------------------------
  void _loadInterstitial() {
    if (!isSupported || _isLoadingInterstitial || _interstitialAd != null) return;
    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingInterstitial = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;
          debugPrint('AdsService: interstitial failed to load: $error');
        },
      ),
    );
  }

  /// Shows an interstitial only if the frequency cap allows.
  /// Returns `true` if an ad was actually shown.
  ///
  /// Optional `onDismissed` fires when the user closes the ad (or immediately
  /// when no ad was shown, so the caller can chain navigation safely).
  Future<bool> maybeShowInterstitial({VoidCallback? onDismissed}) async {
    if (!isSupported) {
      onDismissed?.call();
      return false;
    }

    final now = DateTime.now();
    final gateOpen = _lastInterstitialShownAt == null ||
        now.difference(_lastInterstitialShownAt!) >= _interstitialMinGap;

    if (!gateOpen || _interstitialAd == null) {
      // Make sure one is on the way for next time.
      _loadInterstitial();
      onDismissed?.call();
      return false;
    }

    final ad = _interstitialAd!;
    _interstitialAd = null;
    _lastInterstitialShownAt = now;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdsService: interstitial show failed: $error');
        ad.dispose();
        _loadInterstitial();
        onDismissed?.call();
      },
    );

    await ad.show();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Rewarded
  // ---------------------------------------------------------------------------
  void _loadRewarded() {
    if (!isSupported || _isLoadingRewarded || _rewardedAd != null) return;
    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingRewarded = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewarded = false;
          _rewardedAd = null;
          debugPrint('AdsService: rewarded failed to load: $error');
        },
      ),
    );
  }

  /// Shows a rewarded ad. `onReward` fires only if the user actually earned
  /// the reward (watched far enough). `onUnavailable` fires immediately if no
  /// ad could be shown — caller can fall back to granting the reward for free
  /// or showing an error.
  Future<void> showRewarded({
    required VoidCallback onReward,
    VoidCallback? onUnavailable,
  }) async {
    if (!isSupported || _rewardedAd == null) {
      _loadRewarded();
      (onUnavailable ?? onReward).call();
      return;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null;
    bool earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (earned) onReward();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdsService: rewarded show failed: $error');
        ad.dispose();
        _loadRewarded();
        (onUnavailable ?? onReward).call();
      },
    );

    await ad.show(
      onUserEarnedReward: (_, reward) {
        earned = true;
      },
    );
  }
}
