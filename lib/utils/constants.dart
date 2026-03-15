class AppConstants {
  // App Info
  static const String appName = 'PebbleNote';
  static const String appVersion = '1.1.0';

  // Hive Boxes
  static const String notesBox = 'notes_box';
  static const String settingsBox = 'settings_box';

  // SharedPreferences Keys
  static const String isDarkModeKey = 'is_dark_mode';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String noteCountKey = 'note_count';
  static const String removeAdsKey = 'remove_ads';

  // AdMob App ID
  static const String admobAppId = 'ca-app-pub-4293190177975182~6945827779';

  // Real Ad Unit IDs (production)
  static const String _realBannerAdUnitId =
      'ca-app-pub-4293190177975182/9178907748';
  static const String _realInterstitialAdUnitId =
      'ca-app-pub-4293190177975182/REPLACE_INTERSTITIAL'; // replace when created
  static const String _realRewardedAdUnitId =
      'ca-app-pub-4293190177975182/REPLACE_REWARDED'; // replace when created

  // Google Test Ad Unit IDs (safe for debug — never charge real money)
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // dart.vm.product = true in release, false in debug
  // So when product=true → use real ads, when product=false → use test ads
  static const bool _isRelease = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  );
  static String get bannerAdUnitId =>
      _isRelease ? _realBannerAdUnitId : _testBannerAdUnitId;
  static String get interstitialAdUnitId =>
      _isRelease ? _realInterstitialAdUnitId : _testInterstitialAdUnitId;
  static String get rewardedAdUnitId =>
      _isRelease ? _realRewardedAdUnitId : _testRewardedAdUnitId;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // UI Constants
  static const double borderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 20.0;

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Note Colors
  static const List<String> noteColorNames = [
    'Yellow',
    'Blue',
    'Purple',
    'Pink',
    'Green',
    'Orange',
  ];

  // Onboarding
  static const List<String> onboardingTitles = [];

  static const List<String> onboardingDescriptions = [];
}
