import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';



class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  Locale _currentLocale = const Locale('en');
  Map<String, dynamic> _localizedStrings = {};

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('el', 'GR'), // Greek
  ];

  // Getters
  Locale get currentLocale => _currentLocale;
  Map<String, dynamic> get localizedStrings => _localizedStrings;

  bool get isGreek => _currentLocale.languageCode == 'el';
  bool get isEnglish => _currentLocale.languageCode == 'en';

  // Initialize the service
  Future<void> initialize() async {
    await _loadSavedLanguage();
    await _loadLocalizedStrings();
  }

  // Load saved language preference
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);

      if (savedLanguage != null) {
        _currentLocale = Locale(savedLanguage);
      } else {
        // Default to system locale if supported, otherwise English
        final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
        if (supportedLocales.any(
          (locale) => locale.languageCode == systemLocale.languageCode,
        )) {
          _currentLocale = Locale(systemLocale.languageCode);
        }
      }
    } catch (e) {
      // If any error occurs, default to English
      _currentLocale = const Locale('en');
    }
  }

  // Save language preference
  Future<void> _saveLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _currentLocale.languageCode);
    } catch (e) {
      // Ignore save errors
    }
  }

  // Load localized strings from JSON files
  Future<void> _loadLocalizedStrings() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/translations/${_currentLocale.languageCode}.json',
      );
      _localizedStrings = json.decode(jsonString);
    } catch (e) {
      // Fallback to English if current language fails to load
      if (_currentLocale.languageCode != 'en') {
        try {
          final fallbackJsonString = await rootBundle.loadString(
            'assets/translations/en.json',
          );
          _localizedStrings = json.decode(fallbackJsonString);
        } catch (fallbackError) {
          _localizedStrings = {};
        }
      }
    }
  }

  // Change language
  Future<void> changeLanguage(Locale newLocale) async {
    if (_currentLocale == newLocale) return;

    _currentLocale = newLocale;
    await _loadLocalizedStrings();
    await _saveLanguage();
    notifyListeners();
  }

  // Get localized string by key
  String getString(String key, {Map<String, String>? params}) {
    final keys = key.split('.');
    dynamic value = _localizedStrings;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        // Return the key if translation is not found
        return key;
      }
    }

    var result = value.toString();

    // Replace parameters if provided
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        result = result.replaceAll('{$paramKey}', paramValue);
      });
    }

    return result;
  }

  // Convenience methods for common translations
  String get appTitle => getString('app.title');
  String get loading => getString('app.loading');
  String get error => getString('app.error');
  String get success => getString('app.success');
  String get cancel => getString('app.cancel');
  String get save => getString('app.save');
  String get delete => getString('app.delete');
  String get edit => getString('app.edit');
  String get view => getString('app.view');
  String get add => getString('app.add');
  String get search => getString('app.search');
  String get actions => getString('app.actions');

  // Auth translations
  String get login => getString('auth.login');
  String get logout => getString('auth.logout');
  String get email => getString('auth.email');
  String get password => getString('auth.password');
  String get loginButton => getString('auth.login_button');

  // Navigation translations
  String get dashboard => getString('navigation.dashboard');
  String get students => getString('navigation.students');
  String get reports => getString('navigation.reports');
  String get settings => getString('navigation.settings');

  // Student field translations
  String get studentName => getString('students.fields.name');
  String get studentFamilyName => getString('students.fields.family_name');
  String get studentEmail => getString('students.fields.email');
  String get studentUniversity => getString('students.fields.university');
  String get studentDepartment => getString('students.fields.department');
  String get studentYear => getString('students.fields.year_of_study');
  String get studentPhone => getString('students.fields.phone');
  String get studentCreatedAt => getString('students.fields.created_at');

  // Additional student field translations
  String get studentId => getString('students.fields.student_id');
  String get studentFatherName =>
      getString('students.fields.father_name_short');
  String get studentMotherName =>
      getString('students.fields.mother_name_short');
  String get studentBirthDate => getString('students.fields.birth_date_short');
  String get studentBirthPlace =>
      getString('students.fields.birth_place_short');
  String get studentIdCard => getString('students.fields.id_card_short');
  String get studentIssuingAuthority =>
      getString('students.fields.issuing_authority_short');
  String get studentTaxNumber => getString('students.fields.tax_number_short');
  String get studentHasOtherDegree =>
      getString('students.fields.has_other_degree_short');
  String get studentFatherJob => getString('students.fields.father_job');
  String get studentMotherJob => getString('students.fields.mother_job');
  String get studentParentAddress =>
      getString('students.fields.parent_address');
  String get studentParentCity =>
      getString('students.fields.parent_city_short');
  String get studentParentRegion =>
      getString('students.fields.parent_region_short');
  String get studentParentPostal =>
      getString('students.fields.parent_postal_short');
  String get studentParentCountry =>
      getString('students.fields.parent_country_short');
  String get studentParentPhone =>
      getString('students.fields.parent_phone_short');

  // Language display names
  String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return getString('settings.english');
      case 'el':
        return getString('settings.greek');
      default:
        return languageCode.toUpperCase();
    }
  }

  // Format date according to current locale
  String formatDate(DateTime date) {
    if (isGreek) {
      // Greek date format: dd/MM/yyyy
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } else {
      // English date format: MM/dd/yyyy
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  // Format date for display (e.g., "15 Μαρ 2024" in Greek, "Mar 15, 2024" in English)
  String formatDisplayDate(DateTime date) {
    final months = isGreek
        ? [
            'Ιαν',
            'Φεβ',
            'Μαρ',
            'Απρ',
            'Μαι',
            'Ιουν',
            'Ιουλ',
            'Αυγ',
            'Σεπ',
            'Οκτ',
            'Νοε',
            'Δεκ',
          ]
        : [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];

    final monthName = months[date.month - 1];

    if (isGreek) {
      return '${date.day} $monthName ${date.year}';
    } else {
      return '$monthName ${date.day}, ${date.year}';
    }
  }

  // Get text direction for current locale
  TextDirection get textDirection => _currentLocale.languageCode == 'ar'
      ? TextDirection.rtl
      : TextDirection.ltr;

  // Check if a translation exists
  bool hasTranslation(String key) {
    final keys = key.split('.');
    dynamic value = _localizedStrings;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return false;
      }
    }

    return true;
  }

  // Get all available language options for UI
  List<LanguageOption> get availableLanguages => [
        const LanguageOption(
            code: 'en', name: 'English', nativeName: 'English'),
        const LanguageOption(code: 'el', name: 'Greek', nativeName: 'Ελληνικά'),
      ];
}

// Helper class for language options
@immutable
class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });
  final String code;
  final String name;
  final String nativeName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageOption && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

// Extension for easy access to translations in widgets
extension BuildContextExtensions on BuildContext {
  LanguageService get lang => LanguageService();
}
