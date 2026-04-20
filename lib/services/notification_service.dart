import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'medmate_channel';

  /// Callback invoked when a notification is tapped or fullScreenIntent fires.
  static void Function(String? payload)? _onTap;

  static NotificationDetails _buildDetails(String name) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'MedMate Reminders',
        channelDescription: 'Medication reminder notifications',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        ticker: 'MedMate Alarm',
        styleInformation: BigTextStyleInformation(name),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static Future<void> init(
      {void Function(String? payload)? onNotificationTap}) async {
    _onTap = onNotificationTap;

    tz_data.initializeTimeZones();

    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onTap?.call(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: _backgroundHandler,
    );

    // Create channel explicitly (required Android 8+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      'MedMate Reminders',
      description: 'Medication reminder notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request runtime permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request exact alarm permission (Android 12+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  /// Schedule weekly repeating notifications for each selected day.
  /// [reminderId] — unique int identifying this reminder.
  /// [days] — List<bool> length 7: index 0=Mon … 6=Sun.
  static Future<void> scheduleReminder({
    required int reminderId,
    required String name,
    required String time,
    required List<bool> days,
  }) async {
    await cancelReminder(reminderId);

    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // days index 0=Mon…6=Sun → DateTime.weekday Mon=1…Sun=7
    const weekdayMap = [1, 2, 3, 4, 5, 6, 7];

    for (int i = 0; i < 7; i++) {
      if (!days[i]) continue;

      final notifId = reminderId * 10 + i;
      final scheduledDate =
          _nextInstanceOfWeekdayTime(weekdayMap[i], hour, minute);

      await _plugin.zonedSchedule(
        id: notifId,
        title: '💊 MedMate',
        body: 'ถึงเวลาทานยา: $name',
        payload: '$name|$time',
        scheduledDate: scheduledDate,
        notificationDetails: _buildDetails(name),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
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

  /// Returns details about the notification that launched the app, if any.
  static Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    return await _plugin.getNotificationAppLaunchDetails();
  }

  /// Returns the next TZDateTime on the given [weekday] at [hour]:[minute].
  static tz.TZDateTime _nextInstanceOfWeekdayTime(
      int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Advance until we reach the target weekday
    for (int attempt = 0; attempt < 8; attempt++) {
      if (candidate.weekday == weekday && candidate.isAfter(now)) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }

    return candidate;
  }
}

/// Top-level handler required for background notification responses.
/// Must be a top-level function annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
void _backgroundHandler(NotificationResponse response) {
  // Navigation is handled when the app comes to foreground via _onTap.
}
