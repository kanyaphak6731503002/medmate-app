import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'medmate_channel',
    'MedMate Reminders',
    channelDescription: 'Medication reminder notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  static const NotificationDetails _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings: initSettings);

    // Request runtime permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule weekly repeating notifications for each selected day.
  /// [reminderId] — unique int identifying this reminder (stable across calls).
  /// [days] — List<bool> length 7: index 0=Mon … 6=Sun.
  static Future<void> scheduleReminder({
    required int reminderId,
    required String name,
    required String time,
    required List<bool> days,
  }) async {
    // Cancel old notifications for this reminder first
    await cancelReminder(reminderId);

    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // days index → DateTime.weekday (Mon=1 … Sun=7)
    const weekdayMap = [1, 2, 3, 4, 5, 6, 7];

    for (int i = 0; i < 7; i++) {
      if (!days[i]) continue;

      final notifId = reminderId * 10 + i;
      final scheduledDate =
          _nextInstanceOfWeekdayTime(weekdayMap[i], hour, minute);

      await _plugin.zonedSchedule(
        id: notifId,
        title: 'MedMate — Time to take your medicine',
        body: name,
        scheduledDate: scheduledDate,
        notificationDetails: _notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// Cancel all 7 possible notifications for a given reminder ID.
  static Future<void> cancelReminder(int reminderId) async {
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(id: reminderId * 10 + i);
    }
  }

  /// Returns the next TZDateTime for [weekday] at [hour]:[minute].
  static tz.TZDateTime _nextInstanceOfWeekdayTime(
      int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Advance day-by-day until we land on the right weekday
    while (candidate.weekday != weekday) {
      candidate = candidate.add(const Duration(days: 1));
    }

    // If that time has already passed today/this week, push one week ahead
    if (candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }

    return candidate;
  }
}
