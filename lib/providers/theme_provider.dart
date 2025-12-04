import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  SharedPreferences? _prefs;

  // Customization
  double _fontScale = 1.0; // 0.9=Small, 1.0=Medium, 1.1=Large
  Color _primaryColor = AppTheme.primaryColor;

  ThemeProvider() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;
  double get fontScale => _fontScale;
  Color get primaryColor => _primaryColor;

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs?.getBool(AppConstants.isDarkModeKey) ?? false;
    _fontScale = _prefs?.getDouble('font_scale') ?? 1.0;
    final colorValue =
        _prefs?.getInt('primary_color') ?? AppTheme.primaryColor.toARGB32();
    _primaryColor = Color(colorValue);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs?.setBool(AppConstants.isDarkModeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _prefs?.setBool(AppConstants.isDarkModeKey, _isDarkMode);
      notifyListeners();
    }
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    await _prefs?.setDouble('font_scale', _fontScale);
    notifyListeners();
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    await _prefs?.setInt('primary_color', _primaryColor.toARGB32());
    notifyListeners();
  }

  ThemeData buildLightTheme() {
    final base = AppTheme.lightTheme;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(primary: _primaryColor),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
          fontSize:
              (base.appBarTheme.titleTextStyle?.fontSize ?? 20) * _fontScale,
        ),
      ),
      textTheme: _scaledTextTheme(base.textTheme),
    );
  }

  ThemeData buildDarkTheme() {
    final base = AppTheme.darkTheme;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(primary: _primaryColor),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
          fontSize:
              (base.appBarTheme.titleTextStyle?.fontSize ?? 20) * _fontScale,
        ),
      ),
      textTheme: _scaledTextTheme(base.textTheme),
    );
  }

  TextTheme _scaledTextTheme(TextTheme theme) {
    return theme.copyWith(
      displayLarge: theme.displayLarge?.copyWith(
          fontSize: (theme.displayLarge?.fontSize ?? 57) * _fontScale),
      displayMedium: theme.displayMedium?.copyWith(
          fontSize: (theme.displayMedium?.fontSize ?? 45) * _fontScale),
      displaySmall: theme.displaySmall?.copyWith(
          fontSize: (theme.displaySmall?.fontSize ?? 36) * _fontScale),
      headlineLarge: theme.headlineLarge?.copyWith(
          fontSize: (theme.headlineLarge?.fontSize ?? 32) * _fontScale),
      headlineMedium: theme.headlineMedium?.copyWith(
          fontSize: (theme.headlineMedium?.fontSize ?? 28) * _fontScale),
      headlineSmall: theme.headlineSmall?.copyWith(
          fontSize: (theme.headlineSmall?.fontSize ?? 24) * _fontScale),
      titleLarge: theme.titleLarge
          ?.copyWith(fontSize: (theme.titleLarge?.fontSize ?? 22) * _fontScale),
      titleMedium: theme.titleMedium?.copyWith(
          fontSize: (theme.titleMedium?.fontSize ?? 16) * _fontScale),
      titleSmall: theme.titleSmall
          ?.copyWith(fontSize: (theme.titleSmall?.fontSize ?? 14) * _fontScale),
      bodyLarge: theme.bodyLarge
          ?.copyWith(fontSize: (theme.bodyLarge?.fontSize ?? 16) * _fontScale),
      bodyMedium: theme.bodyMedium
          ?.copyWith(fontSize: (theme.bodyMedium?.fontSize ?? 14) * _fontScale),
      bodySmall: theme.bodySmall
          ?.copyWith(fontSize: (theme.bodySmall?.fontSize ?? 12) * _fontScale),
      labelLarge: theme.labelLarge
          ?.copyWith(fontSize: (theme.labelLarge?.fontSize ?? 14) * _fontScale),
      labelMedium: theme.labelMedium?.copyWith(
          fontSize: (theme.labelMedium?.fontSize ?? 12) * _fontScale),
      labelSmall: theme.labelSmall
          ?.copyWith(fontSize: (theme.labelSmall?.fontSize ?? 11) * _fontScale),
    );
  }
}
