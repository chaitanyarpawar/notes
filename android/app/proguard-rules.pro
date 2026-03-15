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

# Flutter Local Notifications - CRITICAL FOR REMINDERS
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep BroadcastReceivers for scheduled notifications
-keep class * extends android.content.BroadcastReceiver
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }

# Keep AlarmManager and scheduling classes
-keep class android.app.AlarmManager { *; }
-keep class android.app.PendingIntent { *; }
-keep class androidx.core.app.AlarmManagerCompat { *; }

# Keep notification models and data classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

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
