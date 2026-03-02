import 'dart:async';
import 'alarm_storage.dart';

/// Runs a periodic timer that checks whether any enabled alarm matches
/// the current weekday + time. When a match is found it calls [onAlarmFire].
/// 5 minutes after firing, if the user has not confirmed, calls [onAlarmMissed].
class AlarmChecker {
  static Timer? _timer;

  // Fire keys already processed so the same alarm doesn't repeat.
  static final Set<String> _firedKeys = {};

  // Active 5-min miss timers keyed by fireKey.
  static final Map<String, Timer> _missTimers = {};

  /// Start checking every 30 seconds.
  static void start({
    required void Function(String name, String time) onAlarmFire,
    required void Function(String name, String time) onAlarmMissed,
  }) {
    _timer?.cancel();
    _check(onAlarmFire, onAlarmMissed);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _check(onAlarmFire, onAlarmMissed);
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    for (final t in _missTimers.values) {
      t.cancel();
    }
    _missTimers.clear();
  }

  static Future<void> _check(
    void Function(String name, String time) onAlarmFire,
    void Function(String name, String time) onAlarmMissed,
  ) async {
    final now = DateTime.now();
    final currentDayIndex = now.weekday - 1; // Mon=0 … Sun=6

    final alarms = await AlarmStorage.loadAlarms();

    for (final alarm in alarms) {
      final bool enabled = alarm['enabled'] as bool? ?? true;
      if (!enabled) continue;

      final String time = alarm['time'] as String? ?? '';
      final String name = alarm['name'] as String? ?? '';
      final List<bool> days =
          List<bool>.from(alarm['days'] ?? List.filled(7, false));

      if (!days[currentDayIndex]) continue;

      final parts = time.split(':');
      if (parts.length != 2) continue;
      final int? alarmHour = int.tryParse(parts[0]);
      final int? alarmMinute = int.tryParse(parts[1]);
      if (alarmHour == null || alarmMinute == null) continue;

      if (alarmHour == now.hour && alarmMinute == now.minute) {
        final fireKey =
            '$name|$time|$currentDayIndex|${now.year}-${now.month}-${now.day}';

        if (_firedKeys.contains(fireKey)) continue;
        _firedKeys.add(fireKey);

        // Show alarm screen immediately
        onAlarmFire(name, time);

        // After 5 minutes, mark as missed if still not confirmed
        _missTimers[fireKey]?.cancel();
        _missTimers[fireKey] =
            Timer(const Duration(minutes: 5), () async {
          _missTimers.remove(fireKey);
          final latest = await AlarmStorage.loadAlarms();
          for (final a in latest) {
            if (a['name'] == name &&
                a['time'] == time &&
                a['confirmed'] != true) {
              onAlarmMissed(name, time);
              break;
            }
          }
        });

        break; // one alarm at a time to avoid stacking screens
      }
    }
  }
}
