#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// Development script to validate translation files
/// Run with: dart run scripts/validate_translations.dart
void main() async {
  print('🌐 Translation Validation Script');
  print('==================================\n');

  try {
    final validator = TranslationValidator();
    final report = await validator.validate();

    validator.printReport(report);

    if (!report.isValid) {
      exit(1);
    }

    print('✅ All translations are valid!');
  } catch (e) {
    print('❌ Validation failed: $e');
    exit(1);
  }
}

class TranslationValidator {
  static const String translationsPath = 'assets/translations/';
  static const String referenceLocale = 'en';
  static const List<String> supportedLocales = ['en', 'el'];

  Future<ValidationReport> validate() async {
    final report = ValidationReport();

    // Load all translation files
    final translations = <String, Map<String, dynamic>>{};

    for (final locale in supportedLocales) {
      try {
        final file = File('$translationsPath$locale.json');
        if (!await file.exists()) {
          report.errors.add('Translation file missing: $locale.json');
          continue;
        }

        final content = await file.readAsString();
        translations[locale] = json.decode(content) as Map<String, dynamic>;
      } catch (e) {
        report.errors.add('Failed to load $locale.json: $e');
      }
    }

    if (translations.isEmpty) {
      report.errors.add('No valid translation files found');
      return report;
    }

    if (!translations.containsKey(referenceLocale)) {
      report.errors.add('Reference locale ($referenceLocale) not found');
      return report;
    }

    final referenceTranslations = translations[referenceLocale]!;
    final allKeys = _getAllKeys(referenceTranslations);

    // Validate each locale against reference
    for (final locale in supportedLocales) {
      if (locale == referenceLocale) continue;

      if (!translations.containsKey(locale)) continue;

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

    return report;
  }

  List<String> _getAllKeys(Map<String, dynamic> map, [String prefix = '']) {
    final keys = <String>[];

    map.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';

      if (value is Map<String, dynamic>) {
        keys.addAll(_getAllKeys(value, fullKey));
      } else {
        keys.add(fullKey);
      }
    });

    return keys;
  }

  List<String> _findEmptyKeys(Map<String, dynamic> map, [String prefix = '']) {
    final emptyKeys = <String>[];

    map.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';

      if (value is Map<String, dynamic>) {
        emptyKeys.addAll(_findEmptyKeys(value, fullKey));
      } else if (value == null || value.toString().trim().isEmpty) {
        emptyKeys.add(fullKey);
      }
    });

    return emptyKeys;
  }

  void _validateParameters(Map<String, dynamic> reference,
      Map<String, dynamic> target, String locale, ValidationReport report,
      [String prefix = '',]) {
    reference.forEach((key, value) {
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
            report.parameterMismatches[locale] ??=
                <String, ParameterMismatch>{};
            report.parameterMismatches[locale]![fullKey] = ParameterMismatch(
              reference: referenceParams,
              target: targetParams,
            );
          }
        }
      }
    });
  }

  dynamic _getValueByPath(Map<String, dynamic> map, String path) {
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

  Set<String> _extractParameters(String text) {
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(1)!).toSet();
  }

  bool _areParametersSame(Set<String> params1, Set<String> params2) => params1.length == params2.length && params1.every(params2.contains);

  void printReport(ValidationReport report) {
    print('Status: ${report.isValid ? "✅ VALID" : "❌ INVALID"}');

    if (report.errors.isNotEmpty) {
      print('\n🚨 ERRORS:');
      for (final error in report.errors) {
        print('  • $error');
      }
    }

    if (report.missingKeys.isNotEmpty) {
      print('\n📝 MISSING KEYS:');
      report.missingKeys.forEach((locale, keys) {
        print('  $locale: ${keys.length} missing keys');
        for (final key in keys.take(5)) {
          print('    • $key');
        }
        if (keys.length > 5) {
          print('    ... and ${keys.length - 5} more');
        }
      });
    }

    if (report.extraKeys.isNotEmpty) {
      print('\n➕ EXTRA KEYS:');
      report.extraKeys.forEach((locale, keys) {
        print('  $locale: ${keys.length} extra keys');
        for (final key in keys.take(5)) {
          print('    • $key');
        }
        if (keys.length > 5) {
          print('    ... and ${keys.length - 5} more');
        }
      });
    }

    if (report.emptyKeys.isNotEmpty) {
      print('\n🔍 EMPTY KEYS:');
      report.emptyKeys.forEach((locale, keys) {
        print('  $locale: ${keys.length} empty keys');
        for (final key in keys.take(5)) {
          print('    • $key');
        }
        if (keys.length > 5) {
          print('    ... and ${keys.length - 5} more');
        }
      });
    }

    if (report.parameterMismatches.isNotEmpty) {
      print('\n🔗 PARAMETER MISMATCHES:');
      report.parameterMismatches.forEach((locale, mismatches) {
        print('  $locale: ${mismatches.length} parameter mismatches');
        mismatches.forEach((key, mismatch) {
          print('    • $key');
          print('      Reference: {${mismatch.reference.join(', ')}}');
          print('      Target: {${mismatch.target.join(', ')}}');
        });
      });
    }

    print('\n==================================');
  }
}

class ValidationReport {
  bool isValid = true;
  List<String> errors = [];
  Map<String, List<String>> missingKeys = {};
  Map<String, List<String>> extraKeys = {};
  Map<String, List<String>> emptyKeys = {};
  Map<String, Map<String, ParameterMismatch>> parameterMismatches = {};
}

class ParameterMismatch {

  const ParameterMismatch({
    required this.reference,
    required this.target,
  });
  final Set<String> reference;
  final Set<String> target;
}
