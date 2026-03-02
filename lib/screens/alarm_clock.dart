import 'dart:async';
import 'package:flutter/material.dart';
import '../services/language_manager.dart';
import '../services/app_language_state.dart';
import '../services/alarm_storage.dart';

class AlarmClockScreen extends StatefulWidget {
  const AlarmClockScreen({Key? key}) : super(key: key);

  @override
  State<AlarmClockScreen> createState() => _AlarmClockScreenState();
}

class _AlarmClockScreenState extends State<AlarmClockScreen> {
  List<Map<String, dynamic>> _alarms = [];
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    AppLanguageState.addListener(_onLanguageChange);
    _loadAlarms();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    AppLanguageState.removeListener(_onLanguageChange);
    super.dispose();
  }

  void _onLanguageChange() => setState(() {});

  String get _lang => AppLanguageState.currentLanguage;
  String _t(String key) => LanguageManager.getString(key, _lang);

  Future<void> _loadAlarms() async {
    final loaded = await AlarmStorage.loadAlarms();
    setState(() => _alarms = loaded);
  }

  Future<void> _toggleAlarm(int index) async {
    await AlarmStorage.toggleAlarm(_alarms, index);
    setState(() {});
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_t('delete_reminder_title'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('${_t('delete')} "${_alarms[index]['name']}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('cancel'),
                style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AlarmStorage.deleteAlarm(_alarms, index);
              setState(() {});
            },
            child: Text(_t('delete'),
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Build ───────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    _lang == LanguageManager.THAI
                        ? 'นาฬิกาปลุก'
                        : 'Alarm Clock',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _buildLanguageToggle(),
                ],
              ),
            ),

            // ── Live clock ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  // HH:MM in large digits
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _digitBox(hour.substring(0, 1)),
                      _digitBox(hour.substring(1, 2)),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w100,
                            color: Colors.white.withOpacity(0.5),
                            height: 1,
                          ),
                        ),
                      ),
                      _digitBox(minute.substring(0, 1)),
                      _digitBox(minute.substring(1, 2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Seconds
                  Text(
                    second,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF4A90E2).withOpacity(0.7),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Date line
                  Text(
                    _formatDate(_now),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.4),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: Colors.white.withOpacity(0.1), height: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _lang == LanguageManager.THAI
                          ? 'การแจ้งเตือน'
                          : 'Alarms',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.3),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                      child: Divider(
                          color: Colors.white.withOpacity(0.1), height: 1)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Alarm list ───────────────────────────────────────
            Expanded(
              child: _alarms.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: _alarms.length,
                      itemBuilder: (ctx, i) =>
                          _buildAlarmCard(_alarms[i], i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Single digit box ─────────────────────────────────────────────
  Widget _digitBox(String digit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 72,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF4A90E2).withOpacity(0.2), width: 1),
      ),
      child: Center(
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 66,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }

  // ── Date formatter ────────────────────────────────────────────────
  String _formatDate(DateTime d) {
    if (_lang == LanguageManager.THAI) {
      final days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
      final months = [
        '',
        'ม.ค.',
        'ก.พ.',
        'มี.ค.',
        'เม.ย.',
        'พ.ค.',
        'มิ.ย.',
        'ก.ค.',
        'ส.ค.',
        'ก.ย.',
        'ต.ค.',
        'พ.ย.',
        'ธ.ค.'
      ];
      final dayName = days[d.weekday - 1];
      return '$dayName ${d.day} ${months[d.month]} ${d.year + 543}';
    } else {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year}';
    }
  }

  // ── Empty state ───────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off,
              size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            _t('no_reminders_yet'),
            style: TextStyle(
                fontSize: 15, color: Colors.white.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  // ── Alarm card ────────────────────────────────────────────────────
  Widget _buildAlarmCard(Map<String, dynamic> alarm, int index) {
    final bool enabled = alarm['enabled'] as bool? ?? true;
    final String time = alarm['time'] as String? ?? '--:--';
    final String name = alarm['name'] as String? ?? '';
    final String? mealTiming = alarm['mealTiming'] as String?;
    final List<bool> days =
        List<bool>.from(alarm['days'] ?? List.filled(7, false));
    final dayLabels = LanguageManager.getDayAbbreviations(_lang);

    return Dismissible(
      key: ValueKey(alarm['id'] ?? index),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline,
            color: Colors.redAccent, size: 26),
      ),
      confirmDismiss: (_) async {
        _confirmDelete(index);
        return false; // let dialog handle it
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF16213E), Color(0xFF0F3460)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: enabled
                ? const Color(0xFF4A90E2).withOpacity(0.35)
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withOpacity(0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left: time + name + days ──────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w200,
                        color: enabled
                            ? Colors.white
                            : Colors.white.withOpacity(0.25),
                        letterSpacing: 2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Name + meal timing
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: enabled
                                  ? Colors.white70
                                  : Colors.white.withOpacity(0.2),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (mealTiming != null &&
                            mealTiming.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: enabled
                                  ? const Color(0xFF4A90E2)
                                      .withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _t(mealTiming),
                              style: TextStyle(
                                fontSize: 11,
                                color: enabled
                                    ? const Color(0xFF89B8F5)
                                    : Colors.white.withOpacity(0.15),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Day badges
                    Row(
                      children: List.generate(7, (i) {
                        final active = days[i];
                        return Container(
                          margin: const EdgeInsets.only(right: 5),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: (active && enabled)
                                ? const Color(0xFF4A90E2)
                                : Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              dayLabels[i],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: (active && enabled)
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // ── Right: toggle ─────────────────────────────────
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: enabled,
                  onChanged: (_) => _toggleAlarm(index),
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF4A90E2),
                  inactiveThumbColor: Colors.white.withOpacity(0.3),
                  inactiveTrackColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Language toggle ───────────────────────────────────────────────
  Widget _buildLanguageToggle() {
    final isThai = AppLanguageState.currentLanguage == LanguageManager.THAI;
    return GestureDetector(
      onTap: () {
        AppLanguageState.changeLanguage(
            isThai ? LanguageManager.ENGLISH : LanguageManager.THAI);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF4A90E2).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF4A90E2).withOpacity(0.4), width: 1),
        ),
        child: Text(
          isThai ? 'EN' : 'TH',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
