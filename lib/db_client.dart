import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class DatabaseClient {
  // Configuration from secure app config
  static String get _url => AppConfig.supabaseUrl;
  static String get _anonKey => AppConfig.supabaseAnonKey;

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      // Ensure app config is initialized first
      await AppConfig.initialize();
      AppConfig.validate();

      await Supabase.initialize(url: _url, anonKey: _anonKey);
    } catch (e) {
      throw Exception(
        'Database initialization failed. Please check your environment configuration.\nMake sure to run with: flutter run --dart-define-from-file=.env',
      );
    }
  }

  /// Get the Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  /// Check if user is authenticated
  static bool get isAuthenticated => client.auth.currentUser != null;

  /// Get current user
  static User? get currentUser => client.auth.currentUser;
}

// Legacy function for backward compatibility
Future<void> initSupabase() async {
  await DatabaseClient.initialize();
}
