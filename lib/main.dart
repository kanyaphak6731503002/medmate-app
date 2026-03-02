import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medmate/screens/welcome.dart';
import 'package:medmate/screens/alarm_ringing.dart';
import 'services/notification_service.dart';
import 'services/alarm_storage.dart';
import 'services/alarm_checker.dart';

/// Global navigator key — lets us push routes from anywhere (alarms, notifications).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Payload from a notification that launched the app while it was killed/background.
String? pendingAlarmPayload;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init(onNotificationTap: _onNotificationTap);
  await AlarmStorage.rescheduleAll();

  // If app was opened by a fullScreenIntent / notification tap while killed
  final details = await NotificationService.getLaunchDetails();
  if (details != null &&
      details.didNotificationLaunchApp == true &&
      details.notificationResponse?.payload != null) {
    pendingAlarmPayload = details.notificationResponse!.payload;
  }

  runApp(const MyApp());
}

/// Fired by flutter_local_notifications when app is foreground and notification arrives,
/// or when user taps notification from the shade.
void _onNotificationTap(String? payload) => _showAlarmScreen(payload);

/// Push AlarmRingingScreen via navigatorKey (works from any context).
void _showAlarmScreen(String? payload) {
  final parts = (payload ?? '').split('|');
  final name = parts.isNotEmpty ? parts[0] : '';
  final time = parts.length > 1 ? parts[1] : '';
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => AlarmRingingScreen(medicineName: name, alarmTime: time),
      fullscreenDialog: true,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Start the in-app alarm checker after the navigator is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AlarmChecker.start(
        onAlarmFire: (name, time) =>
            _showAlarmScreen('$name|$time'),
        onAlarmMissed: (name, time) async {
          await AlarmStorage.markMissed(name, time);
        },
      );
    });
  }

  @override
  void dispose() {
    AlarmChecker.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedMate',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const Welcome(),
    );
  }
}
