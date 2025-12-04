# ProGuard/R8 rules for PebbleNote
# Optimize and strip unused code while keeping required classes for Flutter, Ads, Sign-In, and Hive

# Flutter engine and generated classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }
-keep class com.google.firebase.** { *; }

# Keep Flutter registrant
-keep class **.GeneratedPluginRegistrant { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.**

# Play Core (SplitCompat / Deferred Components referenced by Flutter)
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# Hive (Dart side; no Java reflection needed, but keep model adapters if any are generated natively)
-keep class **.TypeAdapter { *; }
-keep class **.HiveObject { *; }

# OkHttp/HTTP (if used via plugins)
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Remove all unused code paths
-dontnote
-dontwarn javax.annotation.**

# Enable optimizations
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*
