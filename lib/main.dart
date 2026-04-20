import 'package:flutter/material.dart';
import 'package:medmate/screens/welcome.dart';
import 'package:medmate/screens/alarm_ringing.dart';
import 'services/notification_service.dart';
import 'services/alarm_storage.dart';
import 'services/alarm_checker.dart';
import 'services/supabase_client_provider.dart';

/// Global navigator key — lets us push routes from anywhere (alarms, notifications).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Payload from a notification that launched the app while it was killed/background.
String? pendingAlarmPayload;

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initSupabase();
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

Future<void> _initSupabase() async {
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    debugPrint(
      'Supabase is not configured. Use --dart-define=SUPABASE_URL and --dart-define=SUPABASE_ANON_KEY.',
    );
    return;
  }

  // Supabase anon key is a JWT and should contain dots.
  if (!_supabaseAnonKey.contains('.')) {
    debugPrint(
      'Invalid SUPABASE_ANON_KEY format. Use the anon public key from Supabase Settings > API.',
    );
    return;
  }

  SupabaseClientProvider.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );
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
