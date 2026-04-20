import 'device_identity.dart';
import 'supabase_client_provider.dart';
import 'package:supabase/supabase.dart';

class SupabaseAlarmSync {
  static const String _table = 'alarm_items';

  static SupabaseClient? _clientOrNull() {
    return SupabaseClientProvider.client;
  }

  static Future<void> saveAlarms(List<Map<String, dynamic>> alarms) async {
    final client = _clientOrNull();
    if (client == null) return;

    final deviceId = await DeviceIdentity.getOrCreateDeviceId();
    final rows = alarms
        .map((alarm) => _alarmToRow(deviceId: deviceId, alarm: alarm))
        .toList();

    // Replace the device snapshot atomically from app perspective.
    await client.from(_table).delete().eq('device_id', deviceId);
    if (rows.isEmpty) return;

    await client.from(_table).insert(rows);
  }

  static Future<List<Map<String, dynamic>>?> loadAlarms() async {
    final client = _clientOrNull();
    if (client == null) return null;

    final deviceId = await DeviceIdentity.getOrCreateDeviceId();
    final rows = await client
        .from(_table)
        .select(
          'alarm_id,name,time,days,meal_timing,enabled,confirmed,missed,confirmed_time,confirmed_date,missed_date',
        )
        .eq('device_id', deviceId)
        .order('alarm_id');

    if (rows.isEmpty) return null;

    return rows
        .whereType<Map>()
        .map((row) => _rowToAlarm(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Map<String, dynamic> _alarmToRow({
    required String deviceId,
    required Map<String, dynamic> alarm,
  }) {
    return {
      'device_id': deviceId,
      'alarm_id': _toInt(alarm['id']),
      'name': (alarm['name'] ?? '').toString(),
      'time': (alarm['time'] ?? '').toString(),
      'days': List<bool>.from(alarm['days'] ?? const <bool>[]),
      'meal_timing': alarm['mealTiming']?.toString(),
      'enabled': alarm['enabled'] == true,
      'confirmed': alarm['confirmed'] == true,
      'missed': alarm['missed'] == true,
      'confirmed_time': alarm['confirmedTime']?.toString(),
      'confirmed_date': alarm['confirmedDate']?.toString(),
      'missed_date': alarm['missedDate']?.toString(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static Map<String, dynamic> _rowToAlarm(Map<String, dynamic> row) {
    final rawDays = row['days'];
    final days = (rawDays is List)
        ? rawDays.map((d) => d == true).toList()
        : <bool>[];

    return {
      'id': _toInt(row['alarm_id']),
      'name': (row['name'] ?? '').toString(),
      'time': (row['time'] ?? '').toString(),
      'days': days,
      'mealTiming': row['meal_timing']?.toString() ?? '',
      'enabled': row['enabled'] == true,
      'confirmed': row['confirmed'] == true,
      'missed': row['missed'] == true,
      'confirmedTime': row['confirmed_time']?.toString(),
      'confirmedDate': row['confirmed_date']?.toString(),
      'missedDate': row['missed_date']?.toString(),
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
