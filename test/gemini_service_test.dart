import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wordlune_mobile/services/gemini_service.dart';

void main() {
  group('GeminiService Tests', () {
    late GeminiService geminiService;

    setUpAll(() async {
      // Initialize dotenv with test environment
      await dotenv.load(fileName: '.env');
    });

    setUp(() {
      geminiService = GeminiService();
    });

    test('should throw exception when API key is not configured for example generation', () async {
      // Mock scenario where API key is not configured
      // This test verifies that the service requires Gemini API for example generation
      
      try {
        await geminiService.generateExample('meeting', 'toplantı', sourceLanguage: 'English');
        fail('Expected exception was not thrown');
      } catch (e) {
        expect(e.toString(), contains('Gemini API key is required'));
      }
    });

    test('should handle translation with Google Translate fallback', () async {
      // Translation should work with Google Translate even without Gemini API
      final translation = await geminiService.translateWord('hello');
      
      expect(translation, isNotEmpty);
      expect(translation, isNot(equals('Çeviri hatası')));
    });

    test('should provide word details with translation but handle example generation failure', () async {
      final details = await geminiService.getWordDetails('book');
      
      expect(details, isNotEmpty);
      expect(details['translation'], isNotEmpty);
      expect(details['example'], isNotEmpty);
      
      // Translation should work (Google Translate fallback)
      expect(details['translation'], isNot(equals('Translation error')));
      
      // Example might fail without proper API key
      // This is acceptable as we require Gemini API for creative examples
    });

    test('should work with proper Gemini API key', () async {
      // This test only runs if a valid API key is configured
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      
      if (apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_HERE') {
        final details = await geminiService.getWordDetails('adventure');
        
        expect(details, isNotEmpty);
        expect(details['translation'], isNotEmpty);
        expect(details['example'], isNotEmpty);
        expect(details['translation'], isNot(equals('Translation error')));
        expect(details['example'], isNot(equals('Örnek cümle oluşturulamadı - Gemini API gerekli')));
        expect(details['example']?.toLowerCase().contains('adventure'), isTrue);
      } else {
        print('Skipping API test - no valid Gemini API key configured');
      }
    });

    test('should generate examples in different source languages', () async {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      
      if (apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_HERE') {
        // Test German word
        final germanDetails = await geminiService.getWordDetailsWithLanguages(
          'Freundschaft',
          sourceLanguage: 'German',
          targetLanguage: 'Turkish',
        );
        
        expect(germanDetails, isNotEmpty);
        expect(germanDetails['sourceLanguage'], equals('German'));
        expect(germanDetails['targetLanguage'], equals('Turkish'));
        
        // Test French word
        final frenchDetails = await geminiService.getWordDetailsWithLanguages(
          'bonheur',
          sourceLanguage: 'French',
          targetLanguage: 'Turkish',
        );
        
        expect(frenchDetails, isNotEmpty);
        expect(frenchDetails['sourceLanguage'], equals('French'));
        expect(frenchDetails['targetLanguage'], equals('Turkish'));
        
        print('German example: ${germanDetails['example']}');
        print('French example: ${frenchDetails['example']}');
      } else {
        print('Skipping multi-language test - no valid Gemini API key configured');
      }
    });

    test('should auto-detect source language from language code', () async {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      
      if (apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_HERE') {
        final details = await geminiService.getWordDetailsWithAutoDetection(
          'casa',
          sourceLanguageCode: 'es', // Spanish
          targetLanguage: 'Turkish',
        );
        
        expect(details, isNotEmpty);
        expect(details['sourceLanguage'], equals('Spanish'));
        expect(details['targetLanguage'], equals('Turkish'));
        
        print('Spanish example: ${details['example']}');
      } else {
        print('Skipping auto-detection test - no valid Gemini API key configured');
      }
    });
  });
}
