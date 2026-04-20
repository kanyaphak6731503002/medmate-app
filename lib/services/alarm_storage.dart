import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'supabase_alarm_sync.dart';
import 'supabase_history_sync.dart';

class AlarmStorage {
  static const _key = 'medmate_alarms';
  static const _historyKey = 'medmate_history';

  static String _dayKey([DateTime? date]) {
    final value = date ?? DateTime.now();
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  static bool _isToday(String? dayKey) => dayKey == _dayKey();

  static int _stableAlarmId(Map<String, dynamic> alarm, int index) {
    final name = alarm['name']?.toString() ?? '';
    final time = alarm['time']?.toString() ?? '';
    final meal = alarm['mealTiming']?.toString() ?? '';
    final days = (alarm['days'] is List)
        ? (alarm['days'] as List).map((e) => e == true ? '1' : '0').join()
        : '';
    final seed = '$name|$time|$meal|$days|$index';
    return seed.hashCode.abs();
  }

  static Map<String, dynamic> _ensureAlarmShape(
    Map<String, dynamic> alarm,
    int index,
  ) {
    final normalized = Map<String, dynamic>.from(alarm);
    final parsedId = int.tryParse('${normalized['id'] ?? ''}');
    normalized['id'] = (parsedId == null || parsedId <= 0)
        ? _stableAlarmId(normalized, index)
        : parsedId;

    normalized['enabled'] = normalized['enabled'] == true;
    normalized['confirmed'] = normalized['confirmed'] == true;
    normalized['missed'] = normalized['missed'] == true;
    normalized['days'] = List<bool>.from(normalized['days'] ?? const <bool>[]);
    return normalized;
  }

  static Map<String, dynamic> _normalizeDailyState(Map<String, dynamic> alarm) {
    final normalized = Map<String, dynamic>.from(alarm);
    final confirmedDate = normalized['confirmedDate']?.toString();
    final missedDate = normalized['missedDate']?.toString();

    if (!_isToday(confirmedDate)) {
      normalized['confirmed'] = false;
      normalized['confirmedTime'] = null;
      normalized['confirmedDate'] = null;
    }

    if (!_isToday(missedDate)) {
      normalized['missed'] = false;
      normalized['missedDate'] = null;
    }

    return normalized;
  }

  // ── Listeners (for RemindersScreen to reload when state changes) ──
  static final List<VoidCallback> _listeners = [];
  static void addListener(VoidCallback cb) => _listeners.add(cb);
  static void removeListener(VoidCallback cb) => _listeners.remove(cb);
  static void _notify() {
    for (final cb in List<VoidCallback>.from(_listeners)) {
      cb();
    }
  }

  static Map<String, dynamic> _normalizeHistoryEntry(
      Map<String, dynamic> entry) {
    return {
      'alarmId': entry['alarmId'],
      'eventDate': entry['eventDate'],
      'name': entry['name'],
      'scheduledTime': entry['scheduledTime'],
      'status': entry['status'],
      'confirmedTime': entry['confirmedTime'],
      'updatedAt': entry['updatedAt'],
    };
  }

  /// Load all alarms from persistent storage.
  static Future<List<Map<String, dynamic>>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final List<Map<String, dynamic>> localAlarms;
    if (raw == null) {
      localAlarms = [];
    } else {
      final List decoded = jsonDecode(raw);
      localAlarms = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    try {
      final cloudAlarms = await SupabaseAlarmSync.loadAlarms();
      if (cloudAlarms != null && cloudAlarms.isNotEmpty) {
        final normalizedCloudAlarms = cloudAlarms
            .asMap()
            .entries
            .map((entry) => _normalizeDailyState(
                  _ensureAlarmShape(entry.value, entry.key),
                ))
            .toList();
        final normalizedCloudJson = jsonEncode(normalizedCloudAlarms);
        if (raw != normalizedCloudJson) {
          await prefs.setString(_key, normalizedCloudJson);
        }
        return normalizedCloudAlarms;
      }

      // Cloud has no rows yet: keep local data and seed cloud once.
      if (localAlarms.isNotEmpty) {
        final normalizedForSeed = localAlarms
            .asMap()
            .entries
            .map((entry) => _normalizeDailyState(
                  _ensureAlarmShape(entry.value, entry.key),
                ))
            .toList();
        await SupabaseAlarmSync.saveAlarms(normalizedForSeed);
      }
    } catch (e, st) {
      // Keep the app usable offline or if Supabase is not ready yet.
      if (kDebugMode) {
        debugPrint('Supabase load/sync failed in loadAlarms(): $e');
        debugPrintStack(stackTrace: st);
      }
    }

    final normalizedLocalAlarms = localAlarms
      .asMap()
      .entries
      .map((entry) => _normalizeDailyState(
          _ensureAlarmShape(entry.value, entry.key),
        ))
      .toList();
    final normalizedLocalJson = jsonEncode(normalizedLocalAlarms);
    if (raw != normalizedLocalJson) {
      await prefs.setString(_key, normalizedLocalJson);
    }
    return normalizedLocalAlarms;
  }

  /// Save entire alarm list to persistent storage.
  static Future<void> saveAlarms(List<Map<String, dynamic>> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(alarms);
    await prefs.setString(_key, encoded);
    try {
      await SupabaseAlarmSync.saveAlarms(alarms);
    } catch (e, st) {
      // Local save already succeeded. We'll sync to cloud on next successful write.
      if (kDebugMode) {
        debugPrint('Supabase save failed in saveAlarms(): $e');
        debugPrintStack(stackTrace: st);
      }
    }
    _notify(); // tell listeners (e.g. RemindersScreen) to refresh
  }

  static Future<List<Map<String, dynamic>>> loadHistoryEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    final List<Map<String, dynamic>> localHistory;
    if (raw == null) {
      localHistory = [];
    } else {
      final List decoded = jsonDecode(raw);
      localHistory = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    try {
      final cloudHistory = await SupabaseHistorySync.loadHistory();
      if (cloudHistory != null) {
        final normalized = cloudHistory.map(_normalizeHistoryEntry).toList();
        final encoded = jsonEncode(normalized);
        if (raw != encoded) {
          await prefs.setString(_historyKey, encoded);
        }
        return normalized;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Supabase load/sync failed in loadHistoryEntries(): $e');
        debugPrintStack(stackTrace: st);
      }
    }

    return localHistory.map(_normalizeHistoryEntry).toList();
  }

  static Future<void> _saveHistoryEntries(
      List<Map<String, dynamic>> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(entries));
  }

  static Future<void> _recordHistoryEvent({
    required int alarmId,
    required String name,
    required String scheduledTime,
    required String status,
    String? confirmedTime,
  }) async {
    final entry = {
      'alarmId': alarmId,
      'eventDate': _dayKey(),
      'name': name,
      'scheduledTime': scheduledTime,
      'status': status,
      'confirmedTime': confirmedTime,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    final List<Map<String, dynamic>> history;
    if (raw == null) {
      history = [];
    } else {
      final List decoded = jsonDecode(raw);
      history = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    history.removeWhere((item) =>
        item['alarmId'] == alarmId && item['eventDate'] == entry['eventDate']);
    history.add(entry);
    await _saveHistoryEntries(history);

    try {
      await SupabaseHistorySync.saveHistoryEvent(entry);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Supabase save failed in saveHistoryEvent(): $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  /// Add a new alarm, persist it, and schedule its notifications.
  static Future<void> addAlarm(
      List<Map<String, dynamic>> alarms, Map<String, dynamic> alarm) async {
    final alarmToSave = Map<String, dynamic>.from(alarm);
    final int id = DateTime.now().millisecondsSinceEpoch % 1000000;
    alarmToSave['id'] = id;
    alarmToSave['enabled'] = true;
    alarmToSave['confirmed'] = false;
    alarmToSave['confirmedTime'] = null;
    alarmToSave['confirmedDate'] = null;
    alarmToSave['missed'] = false;
    alarmToSave['missedDate'] = null;
    alarms.add(alarmToSave);
    await saveAlarms(alarms);
    await _scheduleIfEnabled(alarmToSave);
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
          alarm['missedDate'] = _dayKey();
        await _recordHistoryEvent(
          alarmId: alarm['id'] as int,
          name: name,
          scheduledTime: time,
          status: 'missed',
        );
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
    alarms[index]['confirmedDate'] = _dayKey();
    alarms[index]['missedDate'] = null;
    await _recordHistoryEvent(
      alarmId: alarms[index]['id'] as int,
      name: alarms[index]['name'] as String,
      scheduledTime: alarms[index]['time'] as String,
      status: 'taken',
      confirmedTime: confirmedTime,
    );
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
