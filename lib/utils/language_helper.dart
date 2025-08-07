import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utility class for managing language additions and maintenance
class LanguageHelper {
  static const String _translationsPath = 'assets/translations/';
  static const String _referenceLocale = 'en';

  /// Generates a template translation file for a new language
  /// based on the reference locale (English)
  static Future<Map<String, dynamic>> generateLanguageTemplate(
    String newLanguageCode,
  ) async {
    try {
      // Load the reference translation file
      final referenceJsonString = await rootBundle.loadString(
        '$_translationsPath$_referenceLocale.json',
      );
      final referenceTranslations =
          json.decode(referenceJsonString) as Map<String, dynamic>;

      // Create a template with empty values but same structure
      final template = _createEmptyTemplate(referenceTranslations);

      if (kDebugMode) {
        print('Generated template for language: $newLanguageCode');
        print('Total translation keys: ${_countKeys(template)}');
      }

      return template;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating language template: $e');
      }
      rethrow;
    }
  }

  /// Creates an empty template maintaining the structure but with placeholder values
  static Map<String, dynamic> _createEmptyTemplate(
    Map<String, dynamic> source, [
    String prefix = '',
  ]) {
    final template = <String, dynamic>{};

    for (final entry in source.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        template[key] = _createEmptyTemplate(value, '$prefix$key.');
      } else if (value is String) {
        // Keep the structure but mark it as needing translation
        template[key] = _generatePlaceholder(value, '$prefix$key');
      } else {
        template[key] = value;
      }
    }

    return template;
  }

  /// Generates a placeholder that indicates the original text and needs translation
  static String _generatePlaceholder(String originalValue, String key) {
    // If the original contains parameters, preserve them
    if (originalValue.contains('{')) {
      return '[TRANSLATE] $originalValue';
    }
    return '[TRANSLATE] $originalValue';
  }

  /// Counts the total number of translation keys in a nested structure
  static int _countKeys(Map<String, dynamic> map) {
    var count = 0;
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        count += _countKeys(value);
      } else {
        count++;
      }
    }
    return count;
  }

  /// Merges new translations with existing ones, preserving existing translations
  static Map<String, dynamic> mergeTranslations(
    Map<String, dynamic> existing,
    Map<String, dynamic> newTranslations,
  ) {
    final merged = Map<String, dynamic>.from(existing);

    for (final entry in newTranslations.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map<String, dynamic> &&
          merged[key] is Map<String, dynamic>) {
        merged[key] = mergeTranslations(
          merged[key] as Map<String, dynamic>,
          value,
        );
      } else if (!merged.containsKey(key)) {
        // Only add if key doesn't exist
        merged[key] = value;
      }
    }

    return merged;
  }

  /// Validates translation completeness for a specific language
  static TranslationStatus validateLanguage(String languageCode) {
    // This would need to be implemented with actual file reading in production
    // For now, return a placeholder status
    return TranslationStatus(
      languageCode: languageCode,
      totalKeys: 0,
      translatedKeys: 0,
      missingKeys: [],
      emptyKeys: [],
    );
  }

  /// Gets translation progress for all supported languages
  static Future<Map<String, TranslationStatus>> getTranslationProgress() async {
    final progress = <String, TranslationStatus>{};
    final supportedLanguages = ['en', 'el']; // Add more as needed

    for (final language in supportedLanguages) {
      try {
        final status = await _analyzeLanguageFile(language);
        progress[language] = status;
      } catch (e) {
        progress[language] = TranslationStatus(
          languageCode: language,
          totalKeys: 0,
          translatedKeys: 0,
          missingKeys: [],
          emptyKeys: [],
          hasError: true,
          errorMessage: e.toString(),
        );
      }
    }

    return progress;
  }

  /// Analyzes a language file and returns its status
  static Future<TranslationStatus> _analyzeLanguageFile(
    String languageCode,
  ) async {
    try {
      // Load reference file
      final referenceJsonString = await rootBundle.loadString(
        '$_translationsPath$_referenceLocale.json',
      );
      final referenceTranslations =
          json.decode(referenceJsonString) as Map<String, dynamic>;
      final referenceKeys = _getAllKeys(referenceTranslations);

      // Load target file
      final targetJsonString = await rootBundle.loadString(
        '$_translationsPath$languageCode.json',
      );
      final targetTranslations =
          json.decode(targetJsonString) as Map<String, dynamic>;
      final targetKeys = _getAllKeys(targetTranslations);

      // Find missing keys
      final missingKeys =
          referenceKeys.where((key) => !targetKeys.contains(key)).toList();

      // Find empty translations
      final emptyKeys = _findEmptyTranslations(targetTranslations);

      // Count translated keys (non-empty, non-placeholder)
      final translatedKeys = targetKeys.where((key) {
        final value = _getValueByPath(targetTranslations, key);
        return value != null &&
            value.toString().isNotEmpty &&
            !value.toString().startsWith('[TRANSLATE]');
      }).length;

      return TranslationStatus(
        languageCode: languageCode,
        totalKeys: referenceKeys.length,
        translatedKeys: translatedKeys,
        missingKeys: missingKeys,
        emptyKeys: emptyKeys,
      );
    } catch (e) {
      return TranslationStatus(
        languageCode: languageCode,
        totalKeys: 0,
        translatedKeys: 0,
        missingKeys: [],
        emptyKeys: [],
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  /// Gets all keys from a nested map structure
  static List<String> _getAllKeys(
    Map<String, dynamic> map, [
    String prefix = '',
  ]) {
    final keys = <String>[];

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';

      if (value is Map<String, dynamic>) {
        keys.addAll(_getAllKeys(value, fullKey));
      } else {
        keys.add(fullKey);
      }
    }

    return keys;
  }

  /// Finds keys with empty or placeholder translations
  static List<String> _findEmptyTranslations(
    Map<String, dynamic> map, [
    String prefix = '',
  ]) {
    final emptyKeys = <String>[];

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';

      if (value is Map<String, dynamic>) {
        emptyKeys.addAll(_findEmptyTranslations(value, fullKey));
      } else if (value == null ||
          value.toString().trim().isEmpty ||
          value.toString().startsWith('[TRANSLATE]')) {
        emptyKeys.add(fullKey);
      }
    }

    return emptyKeys;
  }

  /// Gets a value from nested map using dot notation path
  static dynamic _getValueByPath(Map<String, dynamic> map, String path) {
    final keys = path.split('.');
    dynamic value = map;

    for (final key in keys) {
      if (value is Map<String, dynamic> && value.containsKey(key)) {
        value = value[key];
      } else {
        return null;
      }
    }

    return value;
  }

  /// Common language configurations for easy setup
  static const Map<String, LanguageConfig> commonLanguages = {
    'es': LanguageConfig(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      isRTL: false,
    ),
    'fr': LanguageConfig(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      isRTL: false,
    ),
    'de': LanguageConfig(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      isRTL: false,
    ),
    'it': LanguageConfig(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      isRTL: false,
    ),
    'pt': LanguageConfig(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      isRTL: false,
    ),
    'ru': LanguageConfig(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      isRTL: false,
    ),
    'zh': LanguageConfig(
      code: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      isRTL: false,
    ),
    'ja': LanguageConfig(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      isRTL: false,
    ),
    'ko': LanguageConfig(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      isRTL: false,
    ),
    'ar': LanguageConfig(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      isRTL: true,
    ),
    'he': LanguageConfig(
      code: 'he',
      name: 'Hebrew',
      nativeName: 'עברית',
      isRTL: true,
    ),
    'tr': LanguageConfig(
      code: 'tr',
      name: 'Turkish',
      nativeName: 'Türkçe',
      isRTL: false,
    ),
    'pl': LanguageConfig(
      code: 'pl',
      name: 'Polish',
      nativeName: 'Polski',
      isRTL: false,
    ),
    'nl': LanguageConfig(
      code: 'nl',
      name: 'Dutch',
      nativeName: 'Nederlands',
      isRTL: false,
    ),
    'sv': LanguageConfig(
      code: 'sv',
      name: 'Swedish',
      nativeName: 'Svenska',
      isRTL: false,
    ),
    'da': LanguageConfig(
      code: 'da',
      name: 'Danish',
      nativeName: 'Dansk',
      isRTL: false,
    ),
    'no': LanguageConfig(
      code: 'no',
      name: 'Norwegian',
      nativeName: 'Norsk',
      isRTL: false,
    ),
    'fi': LanguageConfig(
      code: 'fi',
      name: 'Finnish',
      nativeName: 'Suomi',
      isRTL: false,
    ),
  };

  /// Prints a detailed translation progress report
  static void printProgressReport(Map<String, TranslationStatus> progress) {
    if (kDebugMode) {
      print('\n=== Translation Progress Report ===');

      for (final entry in progress.entries) {
        final language = entry.key;
        final status = entry.value;
        final percentage = status.totalKeys > 0
            ? (status.translatedKeys / status.totalKeys * 100)
                .toStringAsFixed(1)
            : '0.0';

        print(
            '\n🌐 $language (${commonLanguages[language]?.nativeName ?? language.toUpperCase()})',);
        print(
            '   Progress: $percentage% (${status.translatedKeys}/${status.totalKeys})',);

        if (status.hasError) {
          print('   ❌ Error: ${status.errorMessage}');
        } else {
          if (status.missingKeys.isNotEmpty) {
            print('   📝 Missing: ${status.missingKeys.length} keys');
          }
          if (status.emptyKeys.isNotEmpty) {
            print('   🔍 Empty: ${status.emptyKeys.length} keys');
          }
          if (status.isComplete) {
            print('   ✅ Complete!');
          }
        }
      }

      print('\n=== End Report ===\n');
    }
  }
}

/// Represents the translation status for a specific language
class TranslationStatus {

  const TranslationStatus({
    required this.languageCode,
    required this.totalKeys,
    required this.translatedKeys,
    required this.missingKeys,
    required this.emptyKeys,
    this.hasError = false,
    this.errorMessage,
  });
  final String languageCode;
  final int totalKeys;
  final int translatedKeys;
  final List<String> missingKeys;
  final List<String> emptyKeys;
  final bool hasError;
  final String? errorMessage;

  /// Returns true if all translations are complete
  bool get isComplete => !hasError && missingKeys.isEmpty && emptyKeys.isEmpty;

  /// Returns the completion percentage
  double get completionPercentage =>
      totalKeys > 0 ? (translatedKeys / totalKeys) : 0.0;

  /// Returns a human-readable status description
  String get statusDescription {
    if (hasError) return 'Error loading translations';
    if (isComplete) return 'Complete';
    if (translatedKeys == 0) return 'Not started';
    if (completionPercentage < 0.5) return 'In progress (early stage)';
    if (completionPercentage < 0.9) return 'In progress (advanced)';
    return 'Nearly complete';
  }
}

/// Configuration for a language
class LanguageConfig {

  const LanguageConfig({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.isRTL,
  });
  final String code;
  final String name;
  final String nativeName;
  final bool isRTL;
}
