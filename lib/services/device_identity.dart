import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentity {
  static const _key = 'medmate_device_id';

  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(12, (_) => random.nextInt(256));
    final randomHex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final created =
        'device_${DateTime.now().millisecondsSinceEpoch}_$randomHex';

    await prefs.setString(_key, created);
    return created;
  }
}
