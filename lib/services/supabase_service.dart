import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase initialization and gives the rest of the app
/// a single place to reach the client from: SupabaseService.client
class SupabaseService {
  // TODO: replace these with your actual project values.
  // Find them in your Supabase project: Settings > API.
  static const String _supabaseUrl = 'https://pdeuoewtelvhgdejoepc.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBkZXVvZXd0ZWx2aGdkZWpvZXBjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3NzEzMTEsImV4cCI6MjEwNjM0NzMxMX0.85mUCT8pyRLZznNezsZMrM_JTRnI1cOF3R51feuV-aE';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}