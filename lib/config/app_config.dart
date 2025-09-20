/// Application configuration management
/// Handles environment variables and app settings securely using compile-time constants
class AppConfig {
  /// Initialize the configuration (now just validates)
  static Future<void> initialize() async {
    validate();
  }

  /// Get required environment variable from compile-time constants
  static String getRequired(String key) {
    const values = {
      'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
      'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
    };

    final value = values[key];
    if (value == null || value.isEmpty) {
      throw Exception('Required environment variable $key is not set');
    }
    return value;
  }

  /// Get optional environment variable with default
  static String getOptional(String key, String defaultValue) {
    const values = {
      'APP_ENV': String.fromEnvironment('APP_ENV', defaultValue: 'production'),
    };

    return values[key] ?? defaultValue;
  }

  /// Get boolean environment variable
  static bool getBool(String key, {bool defaultValue = false}) {
    const values = {
      'ENABLE_ANALYTICS': bool.fromEnvironment('ENABLE_ANALYTICS'),
    };

    return values[key] ?? defaultValue;
  }

  /// Get integer environment variable
  static int getInt(String key, {int defaultValue = 0}) {
    const values = {
      'SESSION_TIMEOUT':
          int.fromEnvironment('SESSION_TIMEOUT', defaultValue: 3600),
    };

    return values[key] ?? defaultValue;
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
  static bool get enableAnalytics => getBool('ENABLE_ANALYTICS');

  /// Validate all required configuration
  static void validate() {
    final requiredVars = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];

    final missing = <String>[];
    for (final key in requiredVars) {
      try {
        getRequired(key);
      } catch (e) {
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
