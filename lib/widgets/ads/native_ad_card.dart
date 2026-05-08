import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ads_service.dart';

/// Native AdMob ad rendered with Google's `medium` platform template.
///
/// This is intended to be inserted in between list items (every N rows) so the
/// ad sits in the same visual rhythm as the surrounding content. Native ads
/// have the highest eCPM of any format, so they pay best when used sparingly.
///
/// AdMob policy: must always show "Ad" / "Sponsored" attribution. The
/// platform template renders that automatically, so do NOT remove the
/// `mainBackgroundColor`/template — it carries the legally required label.
class NativeAdCard extends StatefulWidget {
  /// Approximate height of the medium template. Tuned so list jumps are minimal.
  static const double estimatedHeight = 320;

  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard>
    with AutomaticKeepAliveClientMixin {
  NativeAd? _ad;
  bool _isLoaded = false;
  bool _failed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AdsService.instance.isSupported) {
      setState(() => _failed = true);
      return;
    }
    await AdsService.instance.initialize();
    if (!mounted) return;

    final ad = NativeAd(
      adUnitId: AdsService.instance.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
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
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF4F8AF4),
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF1E3C72),
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey.shade700,
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey.shade500,
          size: 12,
        ),
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
    super.build(context);
    if (_failed || !AdsService.instance.isSupported) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: NativeAdCard.estimatedHeight,
        child: _isLoaded && _ad != null
            ? AdWidget(ad: _ad!)
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}
