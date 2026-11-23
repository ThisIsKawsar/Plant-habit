import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';
import '../models/habit.dart';

/// Schedules local reminders. Supported on Android, iOS and macOS; a no-op on
/// other platforms.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static const _dailyId = 1;
  static const _weeklyId = 2;
  static const _habitBaseId = 100;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'plant_habit_reminders',
      'Habit reminders',
      channelDescription: 'Daily and habit reminders from Plant Habit',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (!isSupported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (e) {
      debugPrint('NotificationService: timezone fallback to UTC ($e)');
    }
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
        macOS: darwin,
      ),
    );
    _ready = true;
  }

  /// Asks the OS for permission. Returns false if the user declined.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final mac = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (mac != null) {
      return await mac.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  /// Replaces every scheduled notification with ones matching [settings].
  Future<void> reschedule(AppSettings settings, List<Habit> habits) async {
    if (!isSupported) return;
    try {
      await init();
      await _plugin.cancelAll();
      if (!settings.notificationsEnabled) return;

      if (settings.dailyReminderEnabled) {
        await _schedule(
          id: _dailyId,
          title: 'Time to grow 🌱',
          body: "Check in on today's habits and keep your streak alive.",
          at: _nextTime(settings.dailyReminderMinutes),
          match: DateTimeComponents.time,
        );
      }

      if (settings.weeklySummaryEnabled) {
        await _schedule(
          id: _weeklyId,
          title: 'Your weekly summary is ready',
          body: 'See how your habits grew this week.',
          at: _nextTime(18 * 60, weekday: settings.weeklySummaryWeekday),
          match: DateTimeComponents.dayOfWeekAndTime,
        );
      }

      if (settings.habitRemindersEnabled) {
        var id = _habitBaseId;
        for (final h in habits.where((h) => h.enabled && h.reminderEnabled)) {
          final body = h.goal.isEmpty
              ? "Don't forget: ${h.name}"
              : "Don't forget: ${h.name} · ${h.goal}";
          if (h.isEveryDay) {
            await _schedule(
              id: id++,
              title: h.name,
              body: body,
              at: _nextTime(h.reminderMinutes),
              match: DateTimeComponents.time,
            );
          } else {
            for (final wd in h.weekdays) {
              await _schedule(
                id: id++,
                title: h.name,
                body: body,
                at: _nextTime(h.reminderMinutes, weekday: wd),
                match: DateTimeComponents.dayOfWeekAndTime,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('NotificationService: failed to schedule ($e)');
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
    required DateTimeComponents match,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: at,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: match,
    );
  }

  tz.TZDateTime _nextTime(int minutes, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    while (!t.isAfter(now) || (weekday != null && t.weekday != weekday)) {
      t = tz.TZDateTime(tz.local, t.year, t.month, t.day + 1, t.hour, t.minute);
    }
    return t;
  }
}
