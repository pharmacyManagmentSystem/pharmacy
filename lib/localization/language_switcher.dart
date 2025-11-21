import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'app_localizations.dart';

/// A simple language switcher dropdown widget
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.language,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            languageProvider.isArabic ? 'عربي' : 'EN',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      onSelected: (value) {
        if (value == 'ar') {
          languageProvider.setArabic();
        } else {
          languageProvider.setEnglish();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'en',
          child: Row(
            children: [
              Icon(
                languageProvider.locale.languageCode == 'en'
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: languageProvider.locale.languageCode == 'en'
                    ? Colors.green
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('English'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'ar',
          child: Row(
            children: [
              Icon(
                languageProvider.locale.languageCode == 'ar'
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: languageProvider.locale.languageCode == 'ar'
                    ? Colors.green
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('العربية'),
            ],
          ),
        ),
      ],
    );
  }
}

/// A simple toggle button for language switching
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context,
            'EN',
            !languageProvider.isArabic,
            () => languageProvider.setEnglish(),
          ),
          _buildOption(
            context,
            'عربي',
            languageProvider.isArabic,
            () => languageProvider.setArabic(),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// A ListTile for use in settings pages
class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final loc = AppLocalizations.of(context)!;

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(loc.language),
      subtitle: Text(languageProvider.isArabic ? loc.arabic : loc.english),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(loc.language),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('English'),
                  value: 'en',
                  groupValue: languageProvider.locale.languageCode,
                  onChanged: (value) {
                    languageProvider.setEnglish();
                    Navigator.pop(ctx);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('العربية'),
                  value: 'ar',
                  groupValue: languageProvider.locale.languageCode,
                  onChanged: (value) {
                    languageProvider.setArabic();
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

