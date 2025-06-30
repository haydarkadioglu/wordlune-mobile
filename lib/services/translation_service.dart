import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:translator/translator.dart';

class TranslationService {
  static final String? _apiKey = dotenv.env['GOOGLE_TRANSLATE_API_KEY'];
  static const String _baseUrl = 'https://translation.googleapis.com/language/translate/v2';
  static final GoogleTranslator _fallbackTranslator = GoogleTranslator();

  static Future<String> translate({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    // Always use fallback translator since API key is not configured
    if (_apiKey == null || _apiKey!.isEmpty || _apiKey == 'YOUR_GOOGLE_TRANSLATE_API_KEY_HERE') {
      print('Google Translate API key not configured, using fallback translator');
      return await _translateWithFallback(text, targetLanguage, sourceLanguage);
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': text,
          'target': targetLanguage,
          'source': sourceLanguage,
          'key': _apiKey,
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translatedText = data['data']['translations'][0]['translatedText'];
        print('Google Translate API success');
        return translatedText;
      } else if (response.statusCode == 403) {
        print('Google Translate API 403 error (API key invalid/quota exceeded), using fallback translator');
        return await _translateWithFallback(text, targetLanguage, sourceLanguage);
      } else if (response.statusCode == 400) {
        print('Google Translate API 400 error (bad request), using fallback translator');
        return await _translateWithFallback(text, targetLanguage, sourceLanguage);
      } else {
        print('Google Translate API error ${response.statusCode}, using fallback translator');
        return await _translateWithFallback(text, targetLanguage, sourceLanguage);
      }
    } catch (e) {
      print('Google Translate API exception: $e, trying fallback');
      return await _translateWithFallback(text, targetLanguage, sourceLanguage);
    }
  }

  static Future<String> _translateWithFallback(String text, String targetLanguage, String sourceLanguage) async {
    try {
      print('Using free translator package for: "$text" -> $targetLanguage');
      
      // Add timeout to prevent hanging
      final translation = await _fallbackTranslator.translate(
        text,
        from: sourceLanguage == 'auto' ? 'auto' : sourceLanguage,
        to: targetLanguage,
      ).timeout(const Duration(seconds: 10));
      
      print('Fallback translation successful: "${translation.text}"');
      return translation.text;
    } catch (e) {
      print('Fallback translator failed: $e');
      
      // If the fallback also fails, return a more informative message
      if (e.toString().contains('timeout')) {
        return '$text (çeviri zaman aşımı)';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        return '$text (ağ bağlantısı hatası)';
      } else {
        return '$text (çeviri yapılamadı)';
      }
    }
  }

  static Future<String> translateToTurkish(String text) async {
    return await translate(text: text, targetLanguage: 'tr');
  }

  static Future<String> translateToEnglish(String text) async {
    return await translate(text: text, targetLanguage: 'en');
  }

  static Future<String> translateToGerman(String text) async {
    return await translate(text: text, targetLanguage: 'de');
  }

  static Future<String> translateToFrench(String text) async {
    return await translate(text: text, targetLanguage: 'fr');
  }

  static Future<String> translateToSpanish(String text) async {
    return await translate(text: text, targetLanguage: 'es');
  }

  static String getLanguageCode(String language) {
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
      default:
        return 'en';
    }
  }

  // Status checking methods
  static bool get hasValidApiKey {
    return _apiKey != null && 
           _apiKey!.isNotEmpty && 
           _apiKey != 'YOUR_GOOGLE_TRANSLATE_API_KEY_HERE';
  }

  static String get translationStatus {
    if (hasValidApiKey) {
      return 'Google Translate API (Ücretli)';
    } else {
      return 'Ücretsiz Google Çeviri';
    }
  }

  static String get detailedStatus {
    if (hasValidApiKey) {
      return 'Google Translate API kullanılıyor (ücretli, daha hızlı)';
    } else {
      return 'Ücretsiz Google çeviri kullanılıyor (biraz daha yavaş)';
    }
  }
}
