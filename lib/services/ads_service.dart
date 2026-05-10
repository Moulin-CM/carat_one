import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'subscription_service.dart';

/// Central AdMob service.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static const bool useTestAds = true;

  static const _testBannerAndroid       = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos           = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos     = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid     = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos         = 'ca-app-pub-3940256099942544/1712485313';
  static const _testNativeAndroid       = 'ca-app-pub-3940256099942544/2247696110';
  static const _testNativeIos           = 'ca-app-pub-3940256099942544/3986624511';

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

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  DateTime? _lastInterstitialShownAt;

  static const Duration _interstitialMinGap = Duration(seconds: 90);

  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;

  bool get isSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  bool get shouldShowAds {
    final status = SubscriptionService().currentStatus;
    // Pro and Business plans hide ads. Trial also hides ads for better experience if specified, 
    // but usually, we show them in Trial unless we want to showcase the "No Ads" benefit.
    // According to SUBSCRIPTION_PLAN.md: Pro/Business hide ads.
    return !status.isProOrBusiness;
  }

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

  Future<void> initialize() {
    if (!isSupported) return Future.value();
    if (_initialized) return Future.value();
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('AdsService: initialization failed: $e');
    }
  }

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

  Future<bool> maybeShowInterstitial({VoidCallback? onDismissed}) async {
    if (!isSupported || !shouldShowAds) {
      onDismissed?.call();
      return false;
    }

    final now = DateTime.now();
    final gateOpen = _lastInterstitialShownAt == null ||
        now.difference(_lastInterstitialShownAt!) >= _interstitialMinGap;

    if (!gateOpen || _interstitialAd == null) {
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
