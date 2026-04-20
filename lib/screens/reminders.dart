import 'package:flutter/material.dart';
import 'addmedication.dart';
import 'history.dart';
import '../services/language_manager.dart';
import '../services/app_language_state.dart';
import '../services/alarm_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
bool _isToday(String? day) => day == dayKey(DateTime.now());

tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );

  while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

Future<void> scheduleWeeklyReminder({
  required int baseId,
  required String title,
  required String body,
  required List<int> weekdays, // DateTime.monday..sunday
  required int hour,
  required int minute,
}) async {
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'medmate_reminder',
      'Medication Reminder',
      channelDescription: 'Weekly medicine reminders',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  for (final w in weekdays) {
    final id = baseId * 10 + w; // unique per weekday
    await notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfWeekdayTime(w, hour, minute),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}

class Reminder {
  final String id;
  final List<int> weekdays; // DateTime.monday ... DateTime.sunday
  final int hour;
  final int minute;

  Map<String, bool> takenByDate; // <-- ใหม่

  Reminder({
    required this.id,
    required this.weekdays,
    required this.hour,
    required this.minute,
    Map<String, bool>? takenByDate,
  }) : takenByDate = takenByDate ?? {};

  bool isTakenToday() => takenByDate[dayKey(DateTime.now())] ?? false;

  void markTakenToday() {
    takenByDate[dayKey(DateTime.now())] = true;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekdays': weekdays,
        'hour': hour,
        'minute': minute,
        'takenByDate': takenByDate,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'],
        weekdays: List<int>.from(json['weekdays'] ?? []),
        hour: json['hour'],
        minute: json['minute'],
        takenByDate: Map<String, bool>.from(json['takenByDate'] ?? {}),
      );
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Timer? _midnightTimer;

  void _scheduleMidnightRefresh(VoidCallback refresh) {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextMidnight.difference(now), refresh);
  }
  List<Map<String, dynamic>> reminders = [];
  late DateTime selectedDate;
  late DateTime today;
  int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    today = DateTime.now();
    selectedDate = DateTime.now();
    AppLanguageState.addListener(_onLanguageChange);
    AlarmStorage.addListener(_onAlarmStorageChange);
    _loadAlarms();
    _scheduleMidnightRefresh(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    AppLanguageState.removeListener(_onLanguageChange);
    AlarmStorage.removeListener(_onAlarmStorageChange);
    super.dispose();
  }

  void _onLanguageChange() => setState(() {});

  void _onAlarmStorageChange() => _loadAlarms();

  String get _lang => AppLanguageState.currentLanguage;
  String _t(String key) => LanguageManager.getString(key, _lang);

  String _getMonthName(int month) =>
      LanguageManager.getMonthName(month, _lang);

  String _getDateFormat(DateTime date) {
    final month = _getMonthName(date.month);
    return _lang == LanguageManager.THAI
        ? '$month ${date.year + 543}'
        : '$month ${date.year}';
  }

  Future<void> _loadAlarms() async {
    final loaded = await AlarmStorage.loadAlarms();
    setState(() => reminders = loaded);
  }

  void _previousMonth() => setState(() {
        selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
      });

  void _nextMonth() => setState(() {
        selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
      });

  Future<void> _goToAddMedication() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
    );
    if (result != null && result is Map<String, dynamic>) {
      await AlarmStorage.addAlarm(reminders, result);
      setState(() {});
    }
  }

  void _deleteReminder(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('delete_reminder_title')),
        content: Text('${_t('delete')} "${reminders[index]['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AlarmStorage.deleteAlarm(reminders, index);
              setState(() {});
            },
            child: Text(_t('delete'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LanguageManager.getString(
                        'reminders', AppLanguageState.currentLanguage),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  _buildLanguageToggle(),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _buildCalendarHeader(),
            const SizedBox(height: 20),
            _buildCalendar(),
            const SizedBox(height: 30),
            Expanded(
              child: reminders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(_t('no_reminders_yet'),
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[400])),
                          const SizedBox(height: 8),
                          Text(_t('tap_to_add'),
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[400])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: reminders.length,
                      itemBuilder: (context, index) =>
                          _buildReminderCard(reminders[index], index),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () => setState(() => currentTabIndex = 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications,
                      color: currentTabIndex == 0
                          ? const Color(0xFF4A90E2)
                          : Colors.grey),
                  Text(
                    LanguageManager.getString(
                        'reminders', AppLanguageState.currentLanguage),
                    style: TextStyle(
                        fontSize: 11,
                        color: currentTabIndex == 0
                            ? const Color(0xFF4A90E2)
                            : Colors.grey),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _goToAddMedication,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                    color: Color(0xFF4A90E2), shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          HistoryScreen(reminders: reminders)),
                );
                if (result != null && result is Map<String, dynamic>) {
                  await AlarmStorage.addAlarm(reminders, result);
                  setState(() {});
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      color: currentTabIndex == 1
                          ? const Color(0xFF4A90E2)
                          : Colors.grey),
                  Text(
                    LanguageManager.getString(
                        'history', AppLanguageState.currentLanguage),
                    style: TextStyle(
                        fontSize: 11,
                        color: currentTabIndex == 1
                            ? const Color(0xFF4A90E2)
                            : Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          color: const Color(0xFF4A90E2),
          borderRadius: BorderRadius.circular(20),
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

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth),
          Text(_getDateFormat(selectedDate),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstOfMonth =
        DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstWeekday =
        firstOfMonth.weekday == 7 ? 0 : firstOfMonth.weekday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: LanguageManager.getCalendarHeaders(_lang)
                .map((d) => SizedBox(
                    width: 40,
                    child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey)))))
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, childAspectRatio: 1),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday) return const SizedBox();
              final day = index - firstWeekday + 1;
              final isToday = day == today.day &&
                  selectedDate.month == today.month &&
                  selectedDate.year == today.year;
              return Container(
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFF4A90E2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$day',
                      style: TextStyle(
                          color: isToday ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder, int index) {
    final isTakenToday = reminder['confirmed'] == true &&
      _isToday(reminder['confirmedDate']?.toString());
    final isMissedToday = reminder['missed'] == true &&
      _isToday(reminder['missedDate']?.toString());
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(reminder['time'],
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                GestureDetector(
                  onTap: () => _deleteReminder(index),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(reminder['name'],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                if (reminder['mealTiming'] != null &&
                    reminder['mealTiming'].toString().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_t(reminder['mealTiming']),
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4A90E2),
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(7, (i) {
                final days = LanguageManager.getDayAbbreviations(_lang);
                final isActive = reminder['days'][i];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF4A90E2)
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: Text(days[i],
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  isActive ? Colors.white : Colors.black54)),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            isTakenToday
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check,
                          color: Color(0xFF4A90E2), size: 18),
                      const SizedBox(width: 6),
                      Text(_t('taken'),
                          style: const TextStyle(
                              color: Color(0xFF4A90E2),
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  )
                : isMissedToday
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cancel_outlined,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 6),
                            Text(_t('missed'),
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ],
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final now = TimeOfDay.now();
                            final confirmed =
                                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                            await AlarmStorage.confirmAlarm(
                                reminders, index, confirmed);
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(_t('confirm'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}