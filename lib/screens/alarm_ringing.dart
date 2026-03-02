import 'dart:async';
import 'package:flutter/material.dart';
import '../services/language_manager.dart';
import '../services/app_language_state.dart';

class AlarmRingingScreen extends StatefulWidget {
  final String medicineName;
  final String alarmTime;

  const AlarmRingingScreen({
    Key? key,
    required this.medicineName,
    required this.alarmTime,
  }) : super(key: key);

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late Timer _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _lang => AppLanguageState.currentLanguage;

  String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime d) {
    if (_lang == LanguageManager.THAI) {
      const days = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'];
      const months = [
        '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      return 'วัน${days[d.weekday - 1]} ${d.day} ${months[d.month]} ${d.year + 543}';
    } else {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      const months = [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back button from dismissing without tapping button
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A14),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Pulsing alarm icon ──
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4A90E2).withOpacity(0.15),
                    border: Border.all(
                      color: const Color(0xFF4A90E2).withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.alarm,
                    color: Color(0xFF4A90E2),
                    size: 52,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Live clock ──
              Text(
                _formatTime(_now),
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.w100,
                  color: Colors.white,
                  letterSpacing: 4,
                  height: 1,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _formatDate(_now),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 48),

              // ── Medicine info card ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4A90E2).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.medication,
                        color: const Color(0xFF4A90E2).withOpacity(0.8),
                        size: 32),
                    const SizedBox(height: 10),
                    Text(
                      _lang == LanguageManager.THAI
                          ? 'ถึงเวลาทานยาแล้ว!'
                          : "Time to take your medicine!",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.medicineName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Dismiss button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _lang == LanguageManager.THAI ? 'ปิดการแจ้งเตือน' : 'Dismiss',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
