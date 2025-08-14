import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration management
/// Handles environment variables and app settings securely
class AppConfig {
  static bool _initialized = false;

  /// Initialize the configuration
  static Future<void> initialize() async {
    if (!_initialized) {
      await dotenv.load();
      _initialized = true;
    }
  }

  /// Ensure configuration is initialized
  static void _ensureInitialized() {
    if (!_initialized) {
      throw Exception(
        'AppConfig not initialized. Call AppConfig.initialize() first.',
      );
    }
  }

  /// Get required environment variable
  static String getRequired(String key) {
    _ensureInitialized();
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Required environment variable $key is not set');
    }
    return value;
  }

  /// Get optional environment variable with default
  static String getOptional(String key, String defaultValue) {
    _ensureInitialized();
    return dotenv.env[key] ?? defaultValue;
  }

  /// Get boolean environment variable
  static bool getBool(String key, {bool defaultValue = false}) {
    _ensureInitialized();
    final value = dotenv.env[key]?.toLowerCase();
    if (value == null) return defaultValue;
    return value == 'true' || value == '1' || value == 'yes';
  }

  /// Get integer environment variable
  static int getInt(String key, {int defaultValue = 0}) {
    _ensureInitialized();
    final value = dotenv.env[key];
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  // Supabase Configuration
  static String get supabaseUrl => getRequired('SUPABASE_URL');
  static String get supabaseAnonKey => getRequired('SUPABASE_ANON_KEY');

  // App Configuration
  static String get appEnv => getOptional('APP_ENV', 'production');
  static bool get isProduction => appEnv == 'production';
  // Security Settings
  static int get sessionTimeout =>
      getInt('SESSION_TIMEOUT', defaultValue: 3600);

  // Feature Flags
  static bool get useSupabaseAuth =>
      getBool('USE_SUPABASE_AUTH', defaultValue: true);
  static bool get enableAnalytics =>
      getBool('ENABLE_ANALYTICS');

  /// Validate all required configuration
  static void validate() {
    _ensureInitialized();

    final requiredVars = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];

    final missing = <String>[];
    for (final key in requiredVars) {
      if (dotenv.env[key] == null || dotenv.env[key]!.isEmpty) {
        missing.add(key);
      }
    }

    if (missing.isNotEmpty) {
      throw Exception(
        'Missing required environment variables: ${missing.join(', ')}\n'
        'Please ensure your .env file contains all required variables.',
      );
    }

    // Validate Supabase URL format
    final url = supabaseUrl;
    if (!url.startsWith('https://') || !url.contains('supabase.co')) {
      throw Exception('Invalid SUPABASE_URL format');
    }
  }
}
