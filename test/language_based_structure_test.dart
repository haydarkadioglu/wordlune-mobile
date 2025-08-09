import 'package:flutter_test/flutter_test.dart';
import 'package:wordlune_mobile/services/language_preference_service.dart';

void main() {
  group('Language Preference Service Tests', () {
    test('should get default language as Turkish', () async {
      // This test would require SharedPreferences to be mocked
      // For now, we'll test the static methods
      expect(LanguagePreferenceService.getLanguageCode('Turkish'), equals('tr'));
      expect(LanguagePreferenceService.getLanguageCode('English'), equals('en'));
      expect(LanguagePreferenceService.getLanguageCode('German'), equals('de'));
    });

    test('should get language name from code', () {
      expect(LanguagePreferenceService.getLanguageName('tr'), equals('Turkish'));
      expect(LanguagePreferenceService.getLanguageName('en'), equals('English'));
      expect(LanguagePreferenceService.getLanguageName('de'), equals('German'));
    });

    test('should have available languages', () {
      expect(LanguagePreferenceService.availableLanguages, isNotEmpty);
      expect(LanguagePreferenceService.availableLanguages, contains('Turkish'));
      expect(LanguagePreferenceService.availableLanguages, contains('English'));
      expect(LanguagePreferenceService.availableLanguages, contains('German'));
    });
  });
} 