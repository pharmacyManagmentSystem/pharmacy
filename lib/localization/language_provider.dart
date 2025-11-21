import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  
  bool get isArabic => _locale.languageCode == 'ar';

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void toggleLanguage() {
    _locale = _locale.languageCode == 'ar' 
        ? const Locale('en') 
        : const Locale('ar');
    notifyListeners();
  }

  void setArabic() {
    if (_locale.languageCode == 'ar') return;
    _locale = const Locale('ar');
    notifyListeners();
  }

  void setEnglish() {
    if (_locale.languageCode == 'en') return;
    _locale = const Locale('en');
    notifyListeners();
  }
}

