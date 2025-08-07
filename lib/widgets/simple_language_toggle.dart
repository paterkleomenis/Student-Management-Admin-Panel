import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class SimpleLanguageToggle extends StatelessWidget {
  const SimpleLanguageToggle({super.key});

  @override
  Widget build(BuildContext context) => Consumer<LanguageService>(
      builder: (context, langService, child) {
        final isGreek = langService.isGreek;

        return InkWell(
          onTap: () {
            final newLocale = isGreek ? const Locale('en') : const Locale('el');
            langService.changeLanguage(newLocale);

            // Show feedback
            final feedbackMessage = isGreek
                ? langService.getString('language_toggle.changed_to_english')
                : langService.getString('language_toggle.changed_to_greek');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(feedbackMessage),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: isGreek
                      ? langService.getString('language_toggle.ok_english')
                      : langService.getString('language_toggle.ok_greek'),
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.blue[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isGreek ? 'ΕΛ' : 'EN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.language,
                  size: 14,
                  color: Colors.blue[700],
                ),
              ],
            ),
          ),
        );
      },
    );
}
