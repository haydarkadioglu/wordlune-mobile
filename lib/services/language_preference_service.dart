import 'package:shared_preferences/shared_preferences.dart';

class LanguagePreferenceService {
  static const String _languageKey = 'selected_learning_language';
  static const String _translationLanguageKey = 'selected_translation_language';
  
  // Available learning languages
  static const List<String> availableLanguages = [
    'Turkish',
    'English', 
    'German',
    'French',
    'Spanish',
    'Italian',
    'Portuguese',
    'Russian',
    'Japanese',
    'Korean',
    'Chinese',
    'Arabic'
  ];

  // Get the user's selected learning language
  static Future<String> getSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'Turkish'; // Default to Turkish
  }

  // Set the user's selected learning language
  static Future<void> setSelectedLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  // Get language code for Firestore path - returns full language names
  static String getLanguageCode(String language) {
    switch (language.toLowerCase()) {
      case 'turkish':
        return 'turkish';
      case 'english':
        return 'english';
      case 'german':
        return 'german';
      case 'french':
        return 'french';
      case 'spanish':
        return 'spanish';
      case 'italian':
        return 'italian';
      case 'portuguese':
        return 'portuguese';
      case 'russian':
        return 'russian';
      case 'japanese':
        return 'japanese';
      case 'korean':
        return 'korean';
      case 'chinese':
        return 'chinese';
      case 'arabic':
        return 'arabic';
      default:
        return 'turkish'; // Default to Turkish
    }
  }

  // Get language name from code
  static String getLanguageName(String code) {
    switch (code.toLowerCase()) {
      case 'tr':
        return 'Turkish';
      case 'en':
        return 'English';
      case 'de':
        return 'German';
      case 'fr':
        return 'French';
      case 'es':
        return 'Spanish';
      case 'it':
        return 'Italian';
      case 'pt':
        return 'Portuguese';
      case 'ru':
        return 'Russian';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      case 'zh':
        return 'Chinese';
      case 'ar':
        return 'Arabic';
      default:
        return 'Turkish';
    }
  }

  // **TRANSLATION LANGUAGE METHODS**
  
  // Get the user's selected translation target language
  static Future<String> getTranslationLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_translationLanguageKey) ?? 'Turkish'; // Default to Turkish
  }

  // Set the user's selected translation target language
  static Future<void> setTranslationLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_translationLanguageKey, language);
  }

  // Get translation language code for Google Translate API
  static String getTranslationCode(String language) {
    switch (language.toLowerCase()) {
      case 'turkish':
        return 'tr';
      case 'english':
        return 'en';
      case 'german':
        return 'de';
      case 'french':
        return 'fr';
      case 'spanish':
        return 'es';
      case 'italian':
        return 'it';
      case 'portuguese':
        return 'pt';
      case 'russian':
        return 'ru';
      case 'japanese':
        return 'ja';
      case 'korean':
        return 'ko';
      case 'chinese':
        return 'zh';
      case 'arabic':
        return 'ar';
      default:
        return 'tr';
    }
  }

  // Get full language name from code
  static String getLanguageFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'tr':
        return 'Turkish';
      case 'en':
        return 'English';
      case 'de':
        return 'German';
      case 'fr':
        return 'French';
      case 'es':
        return 'Spanish';
      case 'it':
        return 'Italian';
      case 'pt':
        return 'Portuguese';
      case 'ru':
        return 'Russian';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      case 'zh':
        return 'Chinese';
      case 'ar':
        return 'Arabic';
      default:
        return 'Turkish';
    }
  }
} 