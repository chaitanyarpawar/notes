import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/constants.dart';

/// AdMob banner ad widget.
/// - Debug builds  → Google test ad unit (safe, never charged)
/// - Release builds → Real ad unit (ca-app-pub-4293190177975182/9178907748)
class AdMobBannerWidget extends StatefulWidget {
  const AdMobBannerWidget({super.key});

  @override
  State<AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  static const int _maxRetries = 3;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 Loading AdMob banner (${AppConstants.bannerAdUnitId})');
    _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
          debugPrint('✅ AdMob banner loaded');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint(
              '❌ AdMob banner failed (attempt $_retryCount): ${error.message}');
          if (_retryCount < _maxRetries && mounted) {
            _retryCount++;
            // Back-off: 5s, 10s, 15s
            Future.delayed(Duration(seconds: _retryCount * 5), () {
              if (mounted) _loadAd();
            });
          }
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
