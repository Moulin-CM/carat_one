import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ads_service.dart';

/// Adaptive AdMob banner.
///
/// Adaptive banners (vs. classic 320×50) take the device's screen width into
/// account, which Google's docs recommend for higher fill rate and CPM.
///
/// Designed to be safely dropped into:
///   - the bottom slot of a Scaffold (`bottomNavigationBar`-adjacent area)
///   - the end of a scrollable list / column
///   - inside a SafeArea — handles its own bottom padding
///
/// On web / desktop or when ads aren't ready, renders a `SizedBox.shrink()` so
/// it never breaks layouts.
class BannerAdWidget extends StatefulWidget {
  /// Optional max width override. Useful inside narrow side panels.
  final double? maxWidth;

  /// Whether to draw a faint top divider so the banner is visually separated
  /// from the content above it. Defaults to `true`.
  final bool showDivider;

  const BannerAdWidget({
    super.key,
    this.maxWidth,
    this.showDivider = true,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _isLoaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Defer load until first frame so MediaQuery is available for the
    // adaptive width calculation.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    if (!AdsService.instance.isSupported) {
      setState(() => _failed = true);
      return;
    }
    // Make sure SDK is up.
    await AdsService.instance.initialize();
    if (!mounted) return;

    final width = (widget.maxWidth ?? MediaQuery.of(context).size.width).truncate();
    if (width <= 0) return;

    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) {
      setState(() => _failed = true);
      return;
    }

    final ad = BannerAd(
      adUnitId: AdsService.instance.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _failed = true);
        },
      ),
    );

    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || !AdsService.instance.isSupported) {
      return const SizedBox.shrink();
    }
    if (!_isLoaded || _ad == null) {
      // Reserve a small slot while loading so the layout doesn't jump when the
      // ad eventually paints. 60dp matches the typical adaptive banner height.
      return const SizedBox(height: 60);
    }

    final ad = _ad!;
    return Container(
      decoration: widget.showDivider
          ? const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x14000000), width: 0.5),
              ),
            )
          : null,
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: ad),
    );
  }
}

/// Convenience: a SafeArea-wrapped [BannerAdWidget] suitable for placing as
/// the `bottomNavigationBar` of a Scaffold.
class BottomBannerAd extends StatelessWidget {
  const BottomBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      top: false,
      child: BannerAdWidget(),
    );
  }
}
