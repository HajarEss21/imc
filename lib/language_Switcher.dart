import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLocale = languageProvider.locale;

    return DropdownButton<Locale>(
      value: currentLocale,
      icon: const Icon(Icons.language, color: Colors.green),
      underline: Container(height: 0),
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          languageProvider.setLocale(newLocale);
        }
      },
      items: const [
        DropdownMenuItem(
          value: Locale('en'),
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: Locale('fr'),
          child: Text('Français'),
        ),
        DropdownMenuItem(
          value: Locale('ar'),
          child: Text('العربية'),
        ),
        DropdownMenuItem(
          value: Locale('es'),
          child: Text('Español'),
        ),
      ],
    );
  }
}