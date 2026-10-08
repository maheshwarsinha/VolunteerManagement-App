// lib/core/config/supabase_config.dart

class SupabaseConfig {
  /// Supabase Project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rdomnnaaaafdczzmwryi.supabase.co',
  );

  /// Supabase Anon Public Key (Safe for client apps with RLS)
  /// NEVER include service_role secret keys in Flutter client!
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkb21ubmFhYWFmZGN6em13cnlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE0ODI4MjYsImV4cCI6MjEwNzA1ODgyNn0.WyI7janNSYB1x1bB-da_YE7fbT13gZ0abxse1Zi5Chw',
  );

  /// Check if valid cloud credentials are provided
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl != 'https://xyzcompany.supabase.co' &&
      !supabaseAnonKey.contains('dummy');
}
