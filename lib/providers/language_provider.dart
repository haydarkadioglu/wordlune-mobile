import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_preference_service.dart';

class LanguageProvider with ChangeNotifier {
  String _selectedLanguage = 'Turkish';
  Locale _locale = const Locale('tr');
  
  String get selectedLanguage => _selectedLanguage;
  Locale get locale => _locale;

  LanguageProvider() {
    _loadLanguage();
  }

  void _loadLanguage() async {
    _selectedLanguage = await LanguagePreferenceService.getSelectedLanguage();
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'tr';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _selectedLanguage = language;
    await LanguagePreferenceService.setSelectedLanguage(language);
    
    // Set locale based on language
    final languageCode = LanguagePreferenceService.getLanguageCode(language);
    _locale = Locale(languageCode);
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    
    notifyListeners();
    
    print('🌍 Language changed to: $language');
    print('📱 Saved to local storage');
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    
    // Update selected language based on locale
    _selectedLanguage = locale.languageCode == 'en' ? 'English' : 'Turkish';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    await LanguagePreferenceService.setSelectedLanguage(_selectedLanguage);
    
    notifyListeners();
  }

  String get languageCode => LanguagePreferenceService.getLanguageCode(_selectedLanguage);
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isTurkish => _locale.languageCode == 'tr';
}
