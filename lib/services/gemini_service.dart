import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  final GoogleTranslator _translator = GoogleTranslator();

  // Translate word to Turkish using Google Translate
  Future<String> translateWord(String word) async {
    try {
      // Try Google Translate first
      final translation = await _translator.translate(word, from: 'en', to: 'tr');
      final result = translation.text.trim();
      
      // If translation is empty or same as original, try Gemini as fallback
      if (result.isEmpty || result.toLowerCase() == word.toLowerCase()) {
        return await _translateWithGemini(word);
      }
      
      return result;
    } catch (e) {
      try {
        return await _translateWithGemini(word);
      } catch (geminiError) {
        return 'Çeviri hatası';
      }
    }
  }

  // Fallback translation using Gemini
  Future<String> _translateWithGemini(String word) async {
    final prompt = '''
    Translate the English word "$word" to Turkish. 
    Provide only the Turkish translation, nothing else.
    If the word has multiple meanings, provide the most common one.
    ''';

    final response = await _makeRequest(prompt);
    return response.trim();
  }

  // Translate word to specified language using Google Translate
  Future<String> translateWordToLanguage(String word, String targetLanguage) async {
    String languageCode;
    switch (targetLanguage) {
      case 'German':
        languageCode = 'de';
        break;
      case 'French':
        languageCode = 'fr';
        break;
      case 'Spanish':
        languageCode = 'es';
        break;
      case 'English':
        languageCode = 'en';
        break;
      case 'Turkish':
      default:
        languageCode = 'tr';
        break;
    }
    
    try {
      // Try Google Translate first
      final translation = await _translator.translate(word, from: 'en', to: languageCode);
      final result = translation.text.trim();
      
      // If translation is empty or same as original, try Gemini as fallback
      if (result.isEmpty || result.toLowerCase() == word.toLowerCase()) {
        return await _translateWithGeminiToLanguage(word, targetLanguage);
      }
      
      return result;
    } catch (e) {
      try {
        return await _translateWithGeminiToLanguage(word, targetLanguage);
      } catch (geminiError) {
        return 'Çeviri hatası';
      }
    }
  }

  // Fallback translation using Gemini to specified language
  Future<String> _translateWithGeminiToLanguage(String word, String targetLanguage) async {
    final prompt = '''
    Translate the English word "$word" to $targetLanguage. 
    Provide only the $targetLanguage translation, nothing else.
    If the word has multiple meanings, provide the most common one.
    ''';

    final response = await _makeRequest(prompt);
    return response.trim();
  }

  // Generate example sentence
  Future<String> generateExample(String word, String meaning) async {
    try {
      final prompt = '''
      Create a simple English sentence using the word "$word" (which means "$meaning" in Turkish).
      The sentence should be:
      - Easy to understand
      - Natural and commonly used
      - Maximum 15 words
      - Show clear context for the word meaning
      
      Provide only the sentence, nothing else.
      ''';

      final response = await _makeRequest(prompt);
      return response.trim();
    } catch (e) {
      return 'Örnek cümle oluşturulamadı';
    }
  }

  // Get word details (translation + example)
  Future<Map<String, String>> getWordDetails(String word) async {
    try {
      // Get translation using the improved translate method (Google Translate + Gemini fallback)
      final translation = await translateWord(word);
      
      // Generate example using Gemini
      final example = await generateExample(word, translation);
      
      return {
        'translation': translation,
        'example': example,
      };
    } catch (e) {
      return {
        'translation': 'Çeviri hatası',
        'example': 'Örnek cümle oluşturulamadı',
      };
    }
  }

  Future<String> _makeRequest(String prompt) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');
    
    final body = jsonEncode({
      'contents': [{
        'parts': [{
          'text': prompt
        }]
      }],
      'generationConfig': {
        'temperature': 0.3,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      }
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        
        if (parts != null && parts.isNotEmpty) {
          final result = parts[0]['text'] ?? 'Yanıt alınamadı';
          return result;
        }
      }
      
      throw Exception('Invalid response format');
    } else {
      throw Exception('API request failed: ${response.statusCode} - ${response.body}');
    }
  }
}
