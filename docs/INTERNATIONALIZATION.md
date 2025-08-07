# Internationalization (i18n) Guide

This document explains how internationalization is implemented in the Admin Panel application and how to add new languages.

## Overview

The application uses a comprehensive internationalization system that:
- ✅ Eliminates all hardcoded strings
- ✅ Supports multiple languages (currently English and Greek)
- ✅ Provides easy language switching
- ✅ Includes parameter substitution for dynamic content
- ✅ Has validation tools for translation completeness
- ✅ Offers development utilities for managing translations

## Architecture

### Components

1. **LanguageService** (`lib/services/language_service.dart`)
   - Manages language state and switching
   - Loads translations from JSON files
   - Provides translation lookup methods
   - Handles language persistence

2. **Translation Files** (`assets/translations/`)
   - JSON files for each supported language
   - Structured with nested objects for organization
   - Parameter placeholders for dynamic content

3. **Validation Tools** (`lib/utils/`)
   - Translation completeness validation
   - Parameter consistency checking
   - Development utilities

## Current Languages

- **English (en)**: Primary reference language
- **Greek (el)**: Secondary language

## Usage

### Basic Translation Lookup

```dart
// Using LanguageService
final langService = Provider.of<LanguageService>(context);
Text(langService.getString('app.title'))

// Using convenience getters
Text(langService.appTitle)
Text(langService.loading)
Text(langService.students)
```

### Parameter Substitution

```dart
// For strings with parameters like "Hello {name}!"
Text(langService.getString('greeting.message', params: {
  'name': userName,
}))

// For delete confirmation: "Are you sure you want to delete {name}?"
Text(langService.getString('students.delete_dialog.message', params: {
  'name': studentName,
}))
```

### Language Switching

```dart
final langService = Provider.of<LanguageService>(context, listen: false);

// Switch to Greek
await langService.changeLanguage(const Locale('el'));

// Switch to English
await langService.changeLanguage(const Locale('en'));
```

## Translation File Structure

### JSON Format

```json
{
  "app": {
    "title": "Admin Panel - Student Management",
    "loading": "Loading...",
    "error": "Error"
  },
  "navigation": {
    "dashboard": "Dashboard",
    "students": "Students"
  },
  "students": {
    "fields": {
      "name": "Name",
      "email": "Email"
    },
    "messages": {
      "student_deleted": "{name} deleted successfully"
    }
  }
}
```

### Key Naming Conventions

- Use dot notation for nested keys: `students.fields.name`
- Group related translations under common prefixes
- Use descriptive names that indicate context
- Keep parameter names consistent: `{name}`, `{count}`, etc.

## Adding a New Language

### Step 1: Create Translation File

1. Copy the English translation file:
```bash
cp assets/translations/en.json assets/translations/[language_code].json
```

2. Translate all values while keeping the same structure
3. Ensure parameter placeholders remain intact

### Step 2: Update LanguageService

Add the new locale to supported languages:

```dart
// In lib/services/language_service.dart
static const List<Locale> supportedLocales = [
  Locale('en', 'US'),
  Locale('el', 'GR'),
  Locale('es', 'ES'), // New language
];
```

Add convenience methods and display names:

```dart
bool get isSpanish => _currentLocale.languageCode == 'es';

String getLanguageDisplayName(String languageCode) {
  switch (languageCode) {
    case 'en': return getString('settings.english');
    case 'el': return getString('settings.greek');
    case 'es': return getString('settings.spanish'); // Add this
    default: return languageCode.toUpperCase();
  }
}
```

### Step 3: Update Main App

Add the new locale to EasyLocalization:

```dart
// In lib/main.dart
EasyLocalization(
  supportedLocales: const [
    Locale('en'), 
    Locale('el'),
    Locale('es'), // Add this
  ],
  // ...
)
```

### Step 4: Add Display Names

Update translation files to include the new language name:

```json
// In en.json and other files
{
  "settings": {
    "spanish": "Spanish (Español)"
  }
}
```

## Development Tools

### Translation Validation

Run the validation script to check translation completeness:

```bash
dart run scripts/validate_translations.dart
```

This checks for:
- Missing translation keys
- Extra keys not in reference language
- Empty translation values
- Parameter consistency across languages

### Development Screen

In debug mode, access the translation development tools:

```dart
// Add to your route configuration (debug only)
if (kDebugMode) {
  GoRoute(
    path: '/dev/translations',
    builder: (context, state) => const DevTranslationScreen(),
  ),
}
```

Features:
- Translation validation
- Progress tracking
- Template generation for new languages
- Export/import utilities

## Best Practices

### For Developers

1. **Never use hardcoded strings** in UI code
2. **Always use translation keys** through LanguageService
3. **Test with different languages** to ensure UI layout works
4. **Use meaningful key names** that describe the context
5. **Group related translations** under common prefixes
6. **Validate translations** before committing code

### For Translators

1. **Maintain the JSON structure** exactly as in the reference
2. **Keep parameter placeholders** like `{name}` intact
3. **Consider text length differences** that may affect UI
4. **Test the app** with your translations if possible
5. **Ask for context** if translation meaning is unclear
6. **Use consistent terminology** throughout the translation

### Parameter Guidelines

- Use descriptive parameter names: `{studentName}` not `{x}`
- Keep parameters consistent across similar contexts
- Don't translate parameter names themselves
- Ensure all parameters from reference language are included

## Common Issues and Solutions

### Long Text Overflow

Some languages may have longer text than English:

```dart
// Use flexible widgets for text
Flexible(
  child: Text(langService.getString('long.translation.key')),
)

// Or constrain with overflow handling
Text(
  langService.getString('long.translation.key'),
  overflow: TextOverflow.ellipsis,
  maxLines: 2,
)
```

### Date and Number Formatting

Use locale-aware formatting:

```dart
// LanguageService provides locale-specific formatting
Text(langService.formatDisplayDate(DateTime.now()))

// For numbers, use intl package
final formatter = NumberFormat.currency(
  locale: langService.currentLocale.toString(),
  symbol: '€',
);
```

### Missing Translations

The system gracefully handles missing translations:

1. Returns the translation key if not found
2. Logs a debug message
3. Falls back to English if current language fails to load
4. Shows the key so you can identify what needs translation

## File Organization

```
assets/translations/
├── en.json          # English (reference)
├── el.json          # Greek
└── [code].json      # Additional languages

lib/services/
└── language_service.dart    # Main service

lib/utils/
├── translation_validator.dart   # Validation utilities
└── language_helper.dart        # Development helpers

scripts/
└── validate_translations.dart  # CLI validation tool
```

## Testing

### Manual Testing

1. Switch languages using the UI toggle
2. Navigate through all screens
3. Test forms and error messages
4. Verify dynamic content with parameters

### Automated Validation

```bash
# Run translation validation
dart run scripts/validate_translations.dart

# This will check:
# - All languages have the same keys
# - No empty translations
# - Parameter consistency
# - JSON syntax validity
```

## Troubleshooting

### Translation Not Showing

1. Check the key exists in all language files
2. Verify JSON syntax is valid
3. Ensure parameter names match exactly
4. Clear app data to reset language cache

### Language Not Switching

1. Verify locale is in supportedLocales list
2. Check translation file exists and loads
3. Ensure LanguageService.changeLanguage is called
4. Verify Consumer/Provider is properly set up

### Layout Issues

1. Test with longest expected text
2. Use flexible widgets for text display
3. Consider text direction for RTL languages
4. Test on different screen sizes

## Future Enhancements

Planned improvements:

- [ ] Pluralization support
- [ ] Context-aware translations
- [ ] Translation memory integration
- [ ] Automated translation validation in CI/CD
- [ ] Export to translation service formats
- [ ] Import from external translation tools
- [ ] Real-time translation updates
- [ ] A/B testing for different translations

## Contributing

When adding new features:

1. Add all text to translation files first
2. Use LanguageService for all text display
3. Test with multiple languages
4. Run validation script
5. Update this documentation if needed

For translation contributions:

1. Use the template generation tool
2. Follow the style guide for your language
3. Test your translations in the app
4. Submit with validation report