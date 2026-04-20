import 'package:supabase/supabase.dart';

import 'device_identity.dart';
import 'supabase_client_provider.dart';

class SupabaseHistorySync {
  static const String _table = 'alarm_history';

  static SupabaseClient? _clientOrNull() => SupabaseClientProvider.client;

  static Future<void> saveHistoryEvent(Map<String, dynamic> event) async {
    final client = _clientOrNull();
    if (client == null) return;

    final deviceId = await DeviceIdentity.getOrCreateDeviceId();
    await client.from(_table).upsert({
      'device_id': deviceId,
      'alarm_id': _toInt(event['alarmId']),
      'event_date': (event['eventDate'] ?? '').toString(),
      'name': (event['name'] ?? '').toString(),
      'scheduled_time': (event['scheduledTime'] ?? '').toString(),
      'status': (event['status'] ?? '').toString(),
      'confirmed_time': event['confirmedTime']?.toString(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'device_id,event_date,alarm_id');
  }

  static Future<List<Map<String, dynamic>>?> loadHistory() async {
    final client = _clientOrNull();
    if (client == null) return null;

    final deviceId = await DeviceIdentity.getOrCreateDeviceId();
    final rows = await client
        .from(_table)
        .select('alarm_id,event_date,name,scheduled_time,status,confirmed_time,updated_at')
        .eq('device_id', deviceId)
        .order('event_date', ascending: false)
        .order('updated_at', ascending: false);

    if (rows.isEmpty) return null;

    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}