class AppConstants {
  // App Info
  static const String appName = 'PebbleNote';
  static const String appVersion = '1.0.0';

  // Hive Boxes
  static const String notesBox = 'notes_box';
  static const String settingsBox = 'settings_box';

  // SharedPreferences Keys
  static const String isDarkModeKey = 'is_dark_mode';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String noteCountKey = 'note_count';
  static const String removeAdsKey = 'remove_ads';

  // AdMob Test IDs
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Unity Ads Configuration
  static const String unityGameIdAndroid = '6046939';
  static const String unityBannerPlacementId = 'Banner_Android';

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
