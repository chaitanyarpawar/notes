import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import 'navigation_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String _localTimeZone = 'UTC';

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

    // Android 13+ requires runtime notification permission
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled() ?? false;
        if (!enabled) {
          await androidPlugin.requestNotificationsPermission();
        }
        // Request exact alarm permission on Android 12+
        await androidPlugin.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('⚠️ NotificationService: Permission request failed: $e');
    }
    // Create high-priority reminder channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'reminder_channel',
      'Reminders',
      description: 'Scheduled note/checklist reminders',
      importance: Importance.high,
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
    if (!when.isAfter(DateTime.now())) {
      debugPrint(
          '📅 NotificationService: Reminder time ${when.toIso8601String()} is in the past');
      return;
    }

    debugPrint(
        '📅 NotificationService: Scheduling reminder for note ${note.id} at ${when.toIso8601String()}');

    // Build title/body
    final title = note.title.isNotEmpty ? note.title : 'Reminder';
    String body;
    // Treat note with content 'Checklist' or containing checkbox markers as checklist
    final isChecklist = note.content == 'Checklist' ||
        note.content.contains('☐') ||
        note.content.contains('☑');
    if (isChecklist) {
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
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
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

    try {
      await _plugin.zonedSchedule(
        notifId,
        title,
        body,
        tzWhen,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
        payload: json.encode({
          'id': note.id,
          'type': isChecklist ? 'checklist' : 'note',
        }),
      );
      debugPrint('✅ NotificationService: Notification scheduled successfully');
    } catch (e) {
      debugPrint('❌ NotificationService: Failed to schedule notification: $e');
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

  /// Schedules a quick test reminder 5 seconds from now to verify delivery.
  static Future<void> scheduleTestReminder(
      {String title = 'Test Reminder'}) async {
    await initialize();
    final when = DateTime.now().add(const Duration(seconds: 5));
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Scheduled note/checklist reminders',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    final tz.TZDateTime tzWhen = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      // Use a fixed ID for test; it will overwrite prior tests
      999999,
      title,
      'This is a test notification from PebbleNote',
      tzWhen,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      payload: json.encode({'id': 'TEST', 'type': 'note'}),
    );
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
