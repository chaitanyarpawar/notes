import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class AdMobService {
  static late BannerAd _bannerAd;
  static late InterstitialAd _interstitialAd;
  static late RewardedAd _rewardedAd;
  static bool _isBannerLoaded = false;
  static bool _isInterstitialLoaded = false;
  static bool _isRewardedLoaded = false;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ AdMob initialization failed: $e');
      _isInitialized = false;
    }
  }

  // Banner Ad
  static void loadBannerAd({required Function(bool) onAdLoaded}) {
    if (!_isInitialized) {
      onAdLoaded(false);
      return;
    }
    _bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          onAdLoaded(true);
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerLoaded = false;
          ad.dispose();
          onAdLoaded(false);
        },
      ),
    );
    _bannerAd.load();
  }

  static BannerAd? get bannerAd => _isBannerLoaded ? _bannerAd : null;

  // Interstitial Ad
  static void loadInterstitialAd({Function? onAdClosed}) {
    if (!_isInitialized) return;
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialLoaded = false;
              onAdClosed?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialLoaded = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoaded = false;
        },
      ),
    );
  }

  static void showInterstitialAd() {
    if (_isInterstitialLoaded) {
      _interstitialAd.show();
    }
  }

  static bool get isInterstitialReady => _isInterstitialLoaded;

  // Rewarded Ad
  static void loadRewardedAd({Function? onRewarded}) {
    if (!_isInitialized) return;
    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedLoaded = false;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isRewardedLoaded = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoaded = false;
        },
      ),
    );
  }

  static void showRewardedAd({Function? onRewarded}) {
    if (_isRewardedLoaded) {
      _rewardedAd.show(
        onUserEarnedReward: (ad, reward) {
          onRewarded?.call();
        },
      );
    }
  }

  static bool get isRewardedReady => _isRewardedLoaded;

  static void dispose() {
    if (_isBannerLoaded) {
      _bannerAd.dispose();
      _isBannerLoaded = false;
    }
    if (_isInterstitialLoaded) {
      _interstitialAd.dispose();
      _isInterstitialLoaded = false;
    }
    if (_isRewardedLoaded) {
      _rewardedAd.dispose();
      _isRewardedLoaded = false;
    }
  }
}
