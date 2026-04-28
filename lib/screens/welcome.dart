import 'package:flutter/material.dart';
import 'reminders.dart';
import 'alarm_ringing.dart';
import '../services/language_manager.dart';
import '../services/app_language_state.dart';
import '../../main.dart' as app_main;

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    AppLanguageState.addListener(_onLanguageChange);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      // If app was launched from an alarm notification, show alarm screen
      final payload = app_main.pendingAlarmPayload;
      if (payload != null && payload.isNotEmpty) {
        app_main.pendingAlarmPayload = null; // consume it
        final parts = payload.split('|');
        final name = parts.isNotEmpty ? parts[0] : '';
        final time = parts.length > 1 ? parts[1] : '';
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                AlarmRingingScreen(medicineName: name, alarmTime: time),
            fullscreenDialog: true,
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const RemindersScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    AppLanguageState.removeListener(_onLanguageChange);
    _controller.dispose();
    super.dispose();
  }

  void _onLanguageChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth < 520 ? screenWidth * 0.72 : 320.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/rabbit.png',
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                const Text(
                  'MedMate',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90E2),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Medication reminders and tracking',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8FD),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD6E6FA)),
                  ),
                  child: Text(
                    LanguageManager.getString(
                      'medical_disclaimer',
                      AppLanguageState.currentLanguage,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
