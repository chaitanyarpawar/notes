# Build Instructions for Version 1.1.0+13

## Issue Encountered
When attempting to build version 1.1.0+13, encountered persistent plugin registration error:
```
error: package net.jonhanson.flutter_native_splash does not exist
```

## Attempted Solutions
1. ✅ flutter clean + pub get (no effect)
2. ✅ Commented out flutter_native_splash dependency (same error - plugin still referenced in generated code)
3. ✅ Deleted GeneratedPluginRegistrant.java manually (regenerated with same error)
4. ❌ Background job builds - terminal instability

## Root Cause
The `flutter_native_splash` plugin (v2.3.8) appears to have a registration issue where the Android plugin class cannot be found during compilation, even though the package is properly declared in pubspec.yaml.

## Recommended Solution
**Option 1: Use version 1.1.0+12 AAB** (recommended)
- Version 1.1.0+12 was successfully built with all fixes:
  - Google Sign-In deadlock fix (lazy Drive API initialization)
  - All 3 SHA-1 certificates (debug, upload, app signing)
  - USE_EXACT_ALARM removed
  - SCHEDULE_EXACT_ALARM enabled
- File: `build/app/outputs/bundle/release/app-release.aab` (64.2 MB)
- Built on: [check file timestamp]

**Option 2: Update flutter_native_splash**
Try updating to latest version:
```dart
dev_dependencies:
  flutter_native_splash: ^2.4.1  # or latest available
```
Then:
```powershell
flutter clean
flutter pub get
flutter pub run flutter_native_splash:create
flutter build appbundle --release
```

**Option 3: Remove flutter_native_splash entirely** 
The splash screen configuration is already baked into the native Android/iOS code from previous builds. You can:
1. Remove `flutter_native_splash: ^2.3.8` from pubspec.yaml
2. Remove the `flutter_native_splash:` configuration section  
3. Build normally - splash will still work from existing native code

## Current Status
- Version in pubspec.yaml: 1.1.0+12
- flutter_native_splash: Enabled (causing build failures)
- Last successful build: v1.1.0+12 (with all Google Sign-In and policy fixes)
