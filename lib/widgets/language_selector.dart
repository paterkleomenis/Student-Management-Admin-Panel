import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class LanguageSelector extends StatelessWidget {

  const LanguageSelector({super.key, this.showDropdown = true, this.padding});
  final bool showDropdown;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Consumer<LanguageService>(
      builder: (context, languageService, child) {
        if (showDropdown) {
          return _buildDropdownSelector(context, languageService);
        } else {
          return _buildToggleButton(context, languageService);
        }
      },
    );

  Widget _buildDropdownSelector(
    BuildContext context,
    LanguageService languageService,
  ) {
    final currentLanguage = languageService.availableLanguages.firstWhere(
      (lang) => lang.code == languageService.currentLocale.languageCode,
    );

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LanguageOption>(
          value: currentLanguage,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: languageService.availableLanguages.map((language) => DropdownMenuItem<LanguageOption>(
              value: language,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    language.nativeName,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),).toList(),
          onChanged: (LanguageOption? newLanguage) {
            if (newLanguage != null) {
              languageService.changeLanguage(Locale(newLanguage.code));
            }
          },
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    LanguageService languageService,
  ) {
    final isGreek = languageService.isGreek;

    return InkWell(
      onTap: () {
        final newLocale = isGreek ? const Locale('en') : const Locale('el');
        languageService.changeLanguage(newLocale);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isGreek ? 'ΕΛ' : 'EN',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.language,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageSelectorDialog extends StatelessWidget {
  const LanguageSelectorDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog(
      context: context,
      builder: (context) => const LanguageSelectorDialog(),
    );

  @override
  Widget build(BuildContext context) => Consumer<LanguageService>(
      builder: (context, languageService, child) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.language, size: 24),
              const SizedBox(width: 12),
              Text(languageService.getString('settings.language')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languageService.availableLanguages.map((language) {
              final isSelected =
                  language.code == languageService.currentLocale.languageCode;

              return ListTile(
                leading: Icon(
                  Icons.language,
                  size: 24,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                ),
                title: Text(
                  language.nativeName,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                subtitle: Text(
                  language.name,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  if (!isSelected) {
                    languageService.changeLanguage(Locale(language.code));
                  }
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(languageService.cancel),
            ),
          ],
        ),
    );
}

class LanguageFloatingActionButton extends StatelessWidget {
  const LanguageFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) => Consumer<LanguageService>(
      builder: (context, languageService, child) => FloatingActionButton.small(
          onPressed: () => LanguageSelectorDialog.show(context),
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Text(
            languageService.isGreek ? 'ΕΛ' : 'EN',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
    );
}
