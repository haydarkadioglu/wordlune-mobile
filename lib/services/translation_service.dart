import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TranslationService {
  static final String? _apiKey = dotenv.env['GOOGLE_TRANSLATE_API_KEY'];
  static const String _baseUrl = 'https://translation.googleapis.com/language/translate/v2';

  static Future<String> translate({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Google Translate API key not found in .env file');
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
        return translatedText;
      } else {
        throw Exception('Translation failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Translation error: $e');
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
}
