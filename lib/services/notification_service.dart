import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/note.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

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
    await _plugin.initialize(initSettings);
    // Initialize timezone database for zoned scheduling
    tzdata.initializeTimeZones();
    // Use tz.local (platform local timezone when available). For more
    // accurate mapping, integrate flutter_native_timezone and set location.

    // Android 13+ requires runtime notification permission
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (_) {}
    _initialized = true;
  }

  static Future<void> scheduleReminder(Note note) async {
    if (note.reminderTime == null) return;
    await initialize();
    final when = note.reminderTime!;
    if (!when.isAfter(DateTime.now())) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pebblenote_reminders',
      'PebbleNote Reminders',
      channelDescription:
          'Notifications for scheduled note/checklist reminders',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    final tz.TZDateTime tzWhen = tz.TZDateTime.from(when, tz.local);
    // Cancel any existing reminder for this note ID to avoid duplicates
    final int notifId = _stableId(note.id);
    try {
      await _plugin.cancel(notifId);
    } catch (_) {}
    await _plugin.zonedSchedule(
      notifId,
      note.title.isNotEmpty ? note.title : 'Reminder',
      note.content.isNotEmpty ? note.content : 'Open PebbleNote',
      tzWhen,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
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
      'pebblenote_reminders',
      'PebbleNote Reminders',
      channelDescription:
          'Notifications for scheduled note/checklist reminders',
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
    );
  }
}
