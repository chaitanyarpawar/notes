import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isFirstLaunch = true;
  bool _removeAds = false;
  int _noteCount = 0;

  SettingsProvider() {
    _loadSettings();
  }

  // Getters
  bool get isFirstLaunch => _isFirstLaunch;
  bool get removeAds => _removeAds;
  int get noteCount => _noteCount;
  bool get shouldShowInterstitial => _noteCount > 10 && !_removeAds;

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = _prefs?.getBool(AppConstants.isFirstLaunchKey) ?? true;
    _removeAds = _prefs?.getBool(AppConstants.removeAdsKey) ?? false;
    _noteCount = _prefs?.getInt(AppConstants.noteCountKey) ?? 0;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isFirstLaunch = false;
    await _prefs?.setBool(AppConstants.isFirstLaunchKey, false);
    notifyListeners();
  }

  Future<void> incrementNoteCount() async {
    _noteCount++;
    await _prefs?.setInt(AppConstants.noteCountKey, _noteCount);
    notifyListeners();
  }

  Future<void> setRemoveAds(bool value) async {
    _removeAds = value;
    await _prefs?.setBool(AppConstants.removeAdsKey, value);
    notifyListeners();
  }

  Future<void> resetSettings() async {
    _isFirstLaunch = true;
    _removeAds = false;
    _noteCount = 0;

    await _prefs?.setBool(AppConstants.isFirstLaunchKey, true);
    await _prefs?.setBool(AppConstants.removeAdsKey, false);
    await _prefs?.setInt(AppConstants.noteCountKey, 0);

    notifyListeners();
  }
}
