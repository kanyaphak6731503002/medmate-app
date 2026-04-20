import 'package:supabase/supabase.dart';

class SupabaseClientProvider {
  static SupabaseClient? _client;

  static SupabaseClient? get client => _client;

  static bool get isConfigured => _client != null;

  static void initialize({required String url, required String anonKey}) {
    _client = SupabaseClient(url, anonKey);
  }
}
