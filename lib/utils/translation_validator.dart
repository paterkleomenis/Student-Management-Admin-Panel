import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utility class for validating translation completeness across locales
class TranslationValidator {
  static const String _translationsPath = 'assets/translations/';
  static const List<String> _supportedLocales = ['en', 'el'];

  /// Validates all translation files and returns a report
  static Future<ValidationReport> validateTranslations() async {
    final report = ValidationReport();

    try {
      // Load all translation files
      final translations = <String, Map<String, dynamic>>{};

      for (final locale in _supportedLocales) {
        try {
          final jsonString =
              await rootBundle.loadString('$_translationsPath$locale.json');
          translations[locale] = json.decode(jsonString);
        } catch (e) {
          report.errors
              .add('Failed to load translation file for locale: $locale - $e');
          continue;
        }
      }

      if (translations.isEmpty) {
        report.errors.add('No translation files could be loaded');
        return report;
      }

      // Use English as the reference locale
      const referenceLocale = 'en';
      if (!translations.containsKey(referenceLocale)) {
        report.errors.add('Reference locale ($referenceLocale) not found');
        return report;
      }

      final referenceTranslations = translations[referenceLocale]!;
      final allKeys = _getAllKeys(referenceTranslations);

      // Validate each locale against the reference
      for (final locale in _supportedLocales) {
        if (locale == referenceLocale) continue;

        if (!translations.containsKey(locale)) {
          report.errors.add('Translation file missing for locale: $locale');
          continue;
        }

        final localeTranslations = translations[locale]!;
        final localeKeys = _getAllKeys(localeTranslations);

        // Check for missing keys
        final missingKeys =
            allKeys.where((key) => !localeKeys.contains(key)).toList();
        if (missingKeys.isNotEmpty) {
          report.missingKeys[locale] = missingKeys;
        }

        // Check for extra keys
        final extraKeys =
            localeKeys.where((key) => !allKeys.contains(key)).toList();
        if (extraKeys.isNotEmpty) {
          report.extraKeys[locale] = extraKeys;
        }

        // Check for empty values
        final emptyKeys = _findEmptyKeys(localeTranslations);
        if (emptyKeys.isNotEmpty) {
          report.emptyKeys[locale] = emptyKeys;
        }

        // Check for parameter consistency
        _validateParameters(
            referenceTranslations, localeTranslations, locale, report,);
      }

      report.isValid = report.errors.isEmpty &&
          report.missingKeys.isEmpty &&
          report.parameterMismatches.isEmpty;
    } catch (e) {
      report.errors.add('Validation failed with error: $e');
    }

    return report;
  }

  /// Recursively gets all keys from a nested map
  static List<String> _getAllKeys(Map<String, dynamic> map,
      [String prefix = '',]) {
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

  /// Finds keys with empty or null values
  static List<String> _findEmptyKeys(Map<String, dynamic> map,
      [String prefix = '',]) {
    final emptyKeys = <String>[];

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';

      if (value is Map<String, dynamic>) {
        emptyKeys.addAll(_findEmptyKeys(value, fullKey));
      } else if (value == null || value.toString().trim().isEmpty) {
        emptyKeys.add(fullKey);
      }
    }

    return emptyKeys;
  }

  /// Validates parameter consistency between reference and target translations
  static void _validateParameters(Map<String, dynamic> reference,
      Map<String, dynamic> target, String locale, ValidationReport report,
      [String prefix = '',]) {
    for (final entry in reference.entries) {
      final key = entry.key;
      final value = entry.value;
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';

      if (value is Map<String, dynamic>) {
        if (target[key] is Map<String, dynamic>) {
          _validateParameters(value, target[key], locale, report, fullKey);
        }
      } else if (value is String) {
        final targetValue = _getValueByPath(target, fullKey);
        if (targetValue is String) {
          final referenceParams = _extractParameters(value);
          final targetParams = _extractParameters(targetValue);

          if (!_areParametersSame(referenceParams, targetParams)) {
            report.parameterMismatches[locale] ??= {};
            report.parameterMismatches[locale]![fullKey] = ParameterMismatch(
              reference: referenceParams,
              target: targetParams,
            );
          }
        }
      }
    }
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

  /// Extracts parameter names from a translation string (e.g., {name}, {count})
  static Set<String> _extractParameters(String text) {
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(1)!).toSet();
  }

  /// Checks if two parameter sets are the same
  static bool _areParametersSame(Set<String> params1, Set<String> params2) => params1.length == params2.length && params1.every(params2.contains);

  /// Generates a missing translation template for a given locale
  static Map<String, dynamic> generateMissingTranslationTemplate(
    Map<String, dynamic> referenceTranslations,
    List<String> missingKeys,
  ) {
    final template = <String, dynamic>{};

    for (final key in missingKeys) {
      final referenceValue = _getValueByPath(referenceTranslations, key);
      _setValueByPath(template, key, referenceValue ?? '');
    }

    return template;
  }

  /// Sets a value in nested map using dot notation path
  static void _setValueByPath(
      Map<String, dynamic> map, String path, value,) {
    final keys = path.split('.');
    var current = map;

    for (var i = 0; i < keys.length - 1; i++) {
      final key = keys[i];
      if (!current.containsKey(key)) {
        current[key] = <String, dynamic>{};
      }
      current = current[key];
    }

    current[keys.last] = value;
  }

  /// Prints a formatted validation report to debug console
  static void printReport(ValidationReport report) {
    if (kDebugMode) {
      print('\n=== Translation Validation Report ===');
      print('Status: ${report.isValid ? "✅ VALID" : "❌ INVALID"}');

      if (report.errors.isNotEmpty) {
        print('\n🚨 ERRORS:');
        for (final error in report.errors) {
          print('  • $error');
        }
      }

      if (report.missingKeys.isNotEmpty) {
        print('\n📝 MISSING KEYS:');
        for (final entry in report.missingKeys.entries) {
          final locale = entry.key;
          final keys = entry.value;
          print('  $locale: ${keys.length} missing keys');
          for (final key in keys.take(5)) {
            print('    • $key');
          }
          if (keys.length > 5) {
            print('    ... and ${keys.length - 5} more');
          }
        }
      }

      if (report.extraKeys.isNotEmpty) {
        print('\n➕ EXTRA KEYS:');
        for (final entry in report.extraKeys.entries) {
          final locale = entry.key;
          final keys = entry.value;
          print('  $locale: ${keys.length} extra keys');
          for (final key in keys.take(5)) {
            print('    • $key');
          }
          if (keys.length > 5) {
            print('    ... and ${keys.length - 5} more');
          }
        }
      }

      if (report.emptyKeys.isNotEmpty) {
        print('\n🔍 EMPTY KEYS:');
        for (final entry in report.emptyKeys.entries) {
          final locale = entry.key;
          final keys = entry.value;
          print('  $locale: ${keys.length} empty keys');
          for (final key in keys.take(5)) {
            print('    • $key');
          }
          if (keys.length > 5) {
            print('    ... and ${keys.length - 5} more');
          }
        }
      }

      if (report.parameterMismatches.isNotEmpty) {
        print('\n🔗 PARAMETER MISMATCHES:');
        for (final entry in report.parameterMismatches.entries) {
          final locale = entry.key;
          final mismatches = entry.value;
          print('  $locale: ${mismatches.length} parameter mismatches');
          for (final mismatchEntry in mismatches.entries) {
            final key = mismatchEntry.key;
            final mismatch = mismatchEntry.value;
            print('    • $key');
            print('      Reference: {${mismatch.reference.join(', ')}}');
            print('      Target: {${mismatch.target.join(', ')}}');
          }
        }
      }

      print('\n=== End Report ===\n');
    }
  }
}

/// Represents the result of translation validation
class ValidationReport {
  bool isValid = true;
  List<String> errors = [];
  Map<String, List<String>> missingKeys = {};
  Map<String, List<String>> extraKeys = {};
  Map<String, List<String>> emptyKeys = {};
  Map<String, Map<String, ParameterMismatch>> parameterMismatches = {};

  /// Returns true if there are any issues found
  bool get hasIssues =>
      errors.isNotEmpty ||
      missingKeys.isNotEmpty ||
      extraKeys.isNotEmpty ||
      emptyKeys.isNotEmpty ||
      parameterMismatches.isNotEmpty;

  /// Gets a summary of all issues
  String get summary {
    final issues = <String>[];

    if (errors.isNotEmpty) {
      issues.add('${errors.length} errors');
    }

    if (missingKeys.isNotEmpty) {
      final totalMissing = missingKeys.values.fold<int>(
        0,
        (sum, keys) => sum + keys.length,
      );
      issues.add('$totalMissing missing keys');
    }

    if (extraKeys.isNotEmpty) {
      final totalExtra = extraKeys.values.fold<int>(
        0,
        (sum, keys) => sum + keys.length,
      );
      issues.add('$totalExtra extra keys');
    }

    if (emptyKeys.isNotEmpty) {
      final totalEmpty = emptyKeys.values.fold<int>(
        0,
        (sum, keys) => sum + keys.length,
      );
      issues.add('$totalEmpty empty keys');
    }

    if (parameterMismatches.isNotEmpty) {
      final totalMismatches = parameterMismatches.values.fold<int>(
        0,
        (sum, mismatches) => sum + mismatches.length,
      );
      issues.add('$totalMismatches parameter mismatches');
    }

    if (issues.isEmpty) {
      return 'All translations are valid';
    }

    return 'Found: ${issues.join(', ')}';
  }
}

/// Represents a parameter mismatch between reference and target translations
class ParameterMismatch {

  const ParameterMismatch({
    required this.reference,
    required this.target,
  });
  final Set<String> reference;
  final Set<String> target;

  /// Gets parameters that are in reference but missing in target
  Set<String> get missingInTarget => reference.difference(target);

  /// Gets parameters that are in target but not in reference
  Set<String> get extraInTarget => target.difference(reference);
}
