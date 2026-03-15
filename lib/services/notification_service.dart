import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../models/sheet_template.dart';
import 'navigation_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String _localTimeZone = 'UTC';
  static const _platformChannel = MethodChannel('com.pebblenote.app/settings');

  /// Callback to clear reminder from note when notification is delivered/tapped
  static Future<void> Function(String noteId)? onReminderDelivered;

  // Create a stable integer ID from a string. This avoids collisions and
  // remains consistent across app launches unlike Dart's default hashCode.
  static int _stableId(String s) {
    // 32-bit FNV-1a hash
    const int fnvPrime = 0x01000193;
    int hash = 0x811C9DC5;
    for (int i = 0; i < s.length; i++) {
      hash ^= s.codeUnitAt(i);
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    // Ensure fits in signed 31-bit for Android IDs
    return hash & 0x7FFFFFFF;
  }

  // Expose computation for storing in DB
  static int computeNotificationId(String noteId) => _stableId(noteId);

  static Future<void> initialize() async {
    if (_initialized) return;
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: null,
      macOS: null,
      linux: null,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = json.decode(payload) as Map<String, dynamic>;
            final id = data['id'] as String?;
            final type = data['type'] as String?;
            if (id != null && id != 'TEST') {
              // Clear the reminder from the note since it has been delivered
              if (onReminderDelivered != null) {
                await onReminderDelivered!(id);
                debugPrint(
                    '🧹 NotificationService: Cleared reminder for note $id');
              }
              // Navigate to the note/checklist (get fresh context after async)
              final ctx = NavigationService.navigatorKey.currentContext;
              if (ctx != null && ctx.mounted) {
                if (type == 'checklist') {
                  ctx.push('/checklist/$id');
                } else {
                  ctx.push('/note/$id');
                }
              }
            }
          } catch (e) {
            debugPrint(
                '⚠️ NotificationService: Error handling notification: $e');
            // Fallback: open home
            final ctx = NavigationService.navigatorKey.currentContext;
            if (ctx != null && ctx.mounted) {
              ctx.go('/home');
            }
          }
        }
      },
    );
    // Initialize timezone database for zoned scheduling
    tzdata.initializeTimeZones();
    // Get the device's local timezone and set it
    try {
      _localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(_localTimeZone));
      debugPrint('📅 NotificationService: Timezone set to $_localTimeZone');
    } catch (e) {
      debugPrint(
          '⚠️ NotificationService: Failed to get timezone, using UTC: $e');
      _localTimeZone = 'UTC';
      tz.setLocalLocation(tz.UTC);
    }

    // Android 13+ requires runtime notification permission only.
    // Do NOT call requestExactAlarmsPermission() or requestIgnoreBatteryOptimizations()
    // here — those launch system Activities and crash the app when called before
    // the Flutter UI is rendered. They must be triggered from the Settings screen only.
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled() ?? false;
        if (!enabled) {
          await androidPlugin.requestNotificationsPermission();
        }
      }
    } catch (e) {
      debugPrint('⚠️ NotificationService: Permission request failed: $e');
    }

    // Create high-priority reminder channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'reminder_channel',
      'Reminders',
      description: 'Scheduled note/checklist reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Request notification permissions explicitly - call from splash screen
  static Future<bool> requestPermissions() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Request notification permission (Android 13+)
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('🔔 NotificationService: Permission granted: $granted');

        // Request exact alarm permission (Android 12+)
        await androidPlugin.requestExactAlarmsPermission();

        return granted ?? false;
      }
      return true; // Non-Android platforms
    } catch (e) {
      debugPrint('⚠️ NotificationService: Permission request failed: $e');
      return false;
    }
  }

  static Future<void> scheduleReminder(Note note) async {
    if (note.reminderTime == null) {
      debugPrint(
          '📅 NotificationService: No reminder time set for note ${note.id}');
      return;
    }
    await initialize();
    final when = note.reminderTime!;
    final now = DateTime.now();
    if (!when.isAfter(now)) {
      debugPrint(
          '⚠️ NotificationService: Reminder time ${when.toIso8601String()} is in the past (now: ${now.toIso8601String()})');
      return;
    }

    final difference = when.difference(now);
    debugPrint(
        '📅 NotificationService: Scheduling reminder for note ${note.id}');
    debugPrint('   ⏰ Current time: ${now.toIso8601String()}');
    debugPrint('   ⏰ Reminder time: ${when.toIso8601String()}');
    debugPrint(
        '   ⏰ Time until reminder: ${difference.inMinutes} minutes ${difference.inSeconds % 60} seconds');

    // Build title/body
    final title = note.title.isNotEmpty ? note.title : 'Reminder';
    String body;

    // Check if this is a sheet template
    if (note.content.startsWith('__SHEET_DATA__:')) {
      try {
        final jsonString = note.content.substring('__SHEET_DATA__:'.length);
        final sheetData = SheetData.fromJsonString(jsonString);
        final rowCount = sheetData.rows.length;
        final rowText = rowCount == 1 ? 'row' : 'rows';

        if (sheetData.hasTotal) {
          final total = sheetData.calculateTotal();
          body =
              '$rowCount $rowText • Total: ${sheetData.currencySymbol ?? '₹'}${total.toStringAsFixed(2)}';
        } else {
          body =
              '$rowCount $rowText • ${sheetData.columns.map((c) => c.name).take(2).join(', ')}';
        }
      } catch (e) {
        body = 'Excel Sheet';
      }
    }
    // Treat note with content 'Checklist' or containing checkbox markers as checklist
    else if (note.content == 'Checklist' ||
        note.content.contains('☐') ||
        note.content.contains('☑')) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = 'checklist_${note.id}';
        final itemsJson = prefs.getString(key);
        if (itemsJson != null) {
          final list = json.decode(itemsJson) as List<dynamic>;
          final pending =
              list.where((e) => !(e['isChecked'] as bool? ?? false)).length;
          body = pending > 0 ? 'Pending: $pending' : 'Checklist Reminder';
        } else {
          body = 'Checklist Reminder';
        }
      } catch (_) {
        body = 'Checklist Reminder';
      }
    } else {
      // First line of note content
      final c = note.content.trim();
      body = c.isEmpty ? 'Open PebbleNote' : c.split('\n').first;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Scheduled note/checklist reminders',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.reminder,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    final tz.TZDateTime tzWhen = tz.TZDateTime.from(when, tz.local);
    // Cancel any existing reminder for this note ID to avoid duplicates
    final int notifId = _stableId(note.id);
    try {
      await _plugin.cancel(notifId);
    } catch (_) {}

    debugPrint(
        '📅 NotificationService: Scheduling notification ID $notifId for $tzWhen (timezone: $_localTimeZone)');

    // Determine note type for payload
    final isChecklist = note.content == 'Checklist' ||
        note.content.contains('☐') ||
        note.content.contains('☑');

    // Determine if exact alarms are allowed
    // If not, open system settings so user can grant it — do NOT silently fall
    // back to inexact which causes 3-15 min delays.
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final canScheduleExact =
            await androidPlugin.canScheduleExactNotifications() ?? false;
        debugPrint(
            '🔔 NotificationService: Can schedule exact alarms: $canScheduleExact');
        if (!canScheduleExact) {
          // Open Settings so user can enable Alarms & Reminders
          debugPrint(
              '⚠️ NotificationService: Exact alarms not permitted — requesting permission');
          await androidPlugin.requestExactAlarmsPermission();
          // Re-check after request
          final grantedAfter =
              await androidPlugin.canScheduleExactNotifications() ?? false;
          debugPrint(
              '🔔 NotificationService: Permission granted after request: $grantedAfter');
          if (!grantedAfter) {
            // Still not granted: use inexact as last resort
            scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
            debugPrint(
                '⚠️ NotificationService: Using inexact mode as fallback - notifications may be delayed by 3-15 minutes!');
          }
        }
      }
    } catch (e) {
      debugPrint(
          '⚠️ NotificationService: Error checking exact alarm permission: $e');
    }

    try {
      await _plugin.zonedSchedule(
        notifId,
        title,
        body,
        tzWhen,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
        payload: json.encode({
          'id': note.id,
          'type': isChecklist ? 'checklist' : 'note',
        }),
      );
      debugPrint(
          '✅ NotificationService: Notification #$notifId scheduled successfully!');
      debugPrint('   📱 Title: $title');
      debugPrint('   📱 Mode: $scheduleMode');
      debugPrint('   📱 Scheduled for: $tzWhen');

      // Verify by checking pending notifications
      try {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final pending = await androidPlugin?.pendingNotificationRequests();
        if (pending != null) {
          debugPrint('   📋 Total pending notifications: ${pending.length}');
          final thisNotif = pending.where((n) => n.id == notifId);
          if (thisNotif.isNotEmpty) {
            debugPrint(
                '   ✅ Confirmed: Notification #$notifId is in pending queue');
          } else {
            debugPrint(
                '   ⚠️ Warning: Notification #$notifId NOT found in pending queue!');
          }
        }
      } catch (e) {
        debugPrint('   ⚠️ Could not verify pending notifications: $e');
      }
    } catch (e, st) {
      debugPrint(
          '❌ NotificationService: Failed to schedule notification #$notifId: $e');
      debugPrint('❌ Stack trace: $st');
    }
  }

  /// Cancel any scheduled reminder for a given note ID.
  static Future<void> cancelReminderByNoteId(String noteId) async {
    await initialize();
    try {
      await _plugin.cancel(_stableId(noteId));
    } catch (_) {}
  }

  /// Cancel reminder for a Note object.
  static Future<void> cancelReminder(Note note) async {
    await cancelReminderByNoteId(note.id);
  }

  /// Schedules a quick test reminder 10 seconds from now to verify delivery.
  static Future<void> scheduleTestReminder(
      {String title = 'Test Reminder'}) async {
    await initialize();
    final now = DateTime.now();
    final when = now.add(const Duration(seconds: 10));
    debugPrint('🧪 NotificationService: Scheduling TEST notification');
    debugPrint('   ⏰ Current time: ${now.toIso8601String()}');
    debugPrint('   ⏰ Will trigger at: ${when.toIso8601String()}');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Scheduled note/checklist reminders',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.reminder,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    final tz.TZDateTime tzWhen = tz.TZDateTime.from(when, tz.local);

    // Determine schedule mode (same logic as scheduleReminder)
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final canExact =
            await androidPlugin.canScheduleExactNotifications() ?? false;
        debugPrint(
            '🔔 NotificationService: Can schedule exact alarms: $canExact');
        if (!canExact) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          debugPrint(
              '⚠️ NotificationService: Using inexact mode for test (no exact alarm permission)');
        }
      }
    } catch (e) {
      debugPrint('⚠️ NotificationService: Could not check exact alarm: $e');
    }

    try {
      await _plugin.zonedSchedule(
        // Use a fixed ID for test; it will overwrite prior tests
        999999,
        title,
        'Reminders are working! ✅ If you see this, notifications are working properly.',
        tzWhen,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
        payload: json.encode({'id': 'TEST', 'type': 'note'}),
      );
      debugPrint(
          '✅ NotificationService: TEST notification scheduled (mode: $scheduleMode)');
      debugPrint(
          '   ⏰ Please wait 10+ seconds and check if notification appears...');
    } catch (e, st) {
      debugPrint(
          '❌ NotificationService: Failed to schedule TEST notification: $e');
      debugPrint('❌ Stack trace: $st');
    }
  }

  /// Check if app is exempt from battery optimization
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await _platformChannel
              .invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
          true;
    } catch (e) {
      return true;
    }
  }

  /// Request battery optimization exemption (opens system dialog)
  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _platformChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint(
          '⚠️ NotificationService: Could not request battery exemption: $e');
    }
  }

  /// Open the exact alarm settings page (Android 12+)
  static Future<void> openAlarmSettings() async {
    try {
      await _platformChannel.invokeMethod('openAlarmSettings');
    } catch (e) {
      debugPrint('⚠️ NotificationService: Could not open alarm settings: $e');
    }
  }

  /// Check if exact alarms are permitted
  static Future<bool> canScheduleExactAlarms() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.canScheduleExactNotifications() ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Show an immediate notification (no scheduling) to validate delivery.
  static Future<void> showInstantNotification(String title, String body,
      {int? id}) async {
    await initialize();
    final nid = id ?? DateTime.now().millisecondsSinceEpoch % 1000000;
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Scheduled note/checklist reminders',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(nid, title, body, details);
  }
}
