import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class AlarmStorage {
  static const _key = 'medmate_alarms';

  // ── Listeners (for RemindersScreen to reload when state changes) ──
  static final List<VoidCallback> _listeners = [];
  static void addListener(VoidCallback cb) => _listeners.add(cb);
  static void removeListener(VoidCallback cb) => _listeners.remove(cb);
  static void _notify() {
    for (final cb in List<VoidCallback>.from(_listeners)) {
      cb();
    }
  }

  /// Load all alarms from persistent storage.
  static Future<List<Map<String, dynamic>>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Save entire alarm list to persistent storage.
  static Future<void> saveAlarms(List<Map<String, dynamic>> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(alarms));
    _notify(); // tell listeners (e.g. RemindersScreen) to refresh
  }

  /// Add a new alarm, persist it, and schedule its notifications.
  static Future<void> addAlarm(
      List<Map<String, dynamic>> alarms, Map<String, dynamic> alarm) async {
    final int id = DateTime.now().millisecondsSinceEpoch % 1000000;
    alarm['id'] = id;
    alarm['enabled'] = true;
    alarm['confirmed'] = false;
    alarms.add(alarm);
    await saveAlarms(alarms);
    await _scheduleIfEnabled(alarm);
  }

  /// Toggle an alarm on/off and reschedule accordingly.
  static Future<void> toggleAlarm(
      List<Map<String, dynamic>> alarms, int index) async {
    alarms[index]['enabled'] = !(alarms[index]['enabled'] as bool? ?? true);
    await saveAlarms(alarms);
    final alarm = alarms[index];
    final id = alarm['id'] as int;
    if (alarm['enabled'] == true) {
      await _scheduleIfEnabled(alarm);
    } else {
      await NotificationService.cancelReminder(id);
    }
  }

  /// Delete an alarm, cancel notifications, persist.
  static Future<void> deleteAlarm(
      List<Map<String, dynamic>> alarms, int index) async {
    final id = alarms[index]['id'] as int?;
    if (id != null) await NotificationService.cancelReminder(id);
    alarms.removeAt(index);
    await saveAlarms(alarms);
  }

  /// Mark an alarm as missed — called automatically 5 min after alarm fires
  /// if the user has not pressed Confirm.
  static Future<void> markMissed(
      String name, String time) async {
    final alarms = await loadAlarms();
    bool changed = false;
    for (final alarm in alarms) {
      if (alarm['name'] == name &&
          alarm['time'] == time &&
          alarm['confirmed'] != true) {
        alarm['missed'] = true;
        changed = true;
        break;
      }
    }
    if (changed) await saveAlarms(alarms);
  }

  /// Confirm an alarm (mark as taken) and clear any missed flag.
  static Future<void> confirmAlarm(
      List<Map<String, dynamic>> alarms, int index, String confirmedTime) async {
    alarms[index]['confirmed'] = true;
    alarms[index]['missed'] = false;
    alarms[index]['confirmedTime'] = confirmedTime;
    await saveAlarms(alarms);
  }

  /// Re-schedule all enabled alarms — call on app startup to restore
  /// notifications after a phone reboot or app update.
  static Future<void> rescheduleAll() async {
    final alarms = await loadAlarms();
    for (final alarm in alarms) {
      await _scheduleIfEnabled(alarm);
    }
  }

  static Future<void> _scheduleIfEnabled(Map<String, dynamic> alarm) async {
    if (alarm['enabled'] != true) return;
    await NotificationService.scheduleReminder(
      reminderId: alarm['id'] as int,
      name: alarm['name'] as String,
      time: alarm['time'] as String,
      days: List<bool>.from(alarm['days']),
    );
  }
}
