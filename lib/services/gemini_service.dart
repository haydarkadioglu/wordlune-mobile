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

  // Generate example sentence using advanced linguist prompt
  Future<String> generateExample(String word, String meaning, {String sourceLanguage = 'English'}) async {
    // Check if API key is available and valid
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Gemini API key is required for example generation. Please configure GEMINI_API_KEY in .env file.');
    }

    try {
      final prompt = '''
You are an expert linguist and translator. Your task is to process the word "$word".
For this word, you must perform two actions:
1. Create a concise and natural-sounding example sentence that clearly demonstrates the word's meaning. The source language is $sourceLanguage.
2. Translate the word into Turkish. Provide the most common and relevant translation.

Requirements for the example sentence:
- Use natural, conversational language in $sourceLanguage
- Maximum 15 words
- Show clear context for the word meaning
- Be creative and varied - avoid common patterns
- Make it engaging and realistic
- Use diverse sentence structures (questions, exclamations, narratives, etc.)
- Incorporate different contexts (work, daily life, emotions, scenarios)
- Vary the word's position in the sentence
- Include relevant adjectives, adverbs, or context clues

Examples of creative variety for different languages:
- English: "Her brilliant idea saved the company millions of dollars."
- German: "Seine mutige Entscheidung veränderte alles für das Team."
- French: "Cette magnifique histoire nous a tous touchés profondément."
- Spanish: "Su increíble talento sorprendió a toda la audiencia."
- Turkish: "Bu harika fikir herkesi çok etkiledi ve ilham verdi."

Provide only the example sentence in $sourceLanguage, nothing else. Do not include the translation in your response.
      ''';

      final response = await _makeRequest(prompt);
      return response.trim();
    } catch (e) {
      // No local fallback - throw the error to indicate Gemini is required
      throw Exception('Failed to generate example sentence: ${e.toString()}');
    }
  }

  // Get word details (translation + example)
  Future<Map<String, String>> getWordDetails(String word, {String sourceLanguage = 'English'}) async {
    try {
      // Get translation using the improved translate method (Google Translate + Gemini fallback)
      final translation = await translateWord(word);
      
      // Generate example using Gemini with specified source language
      final example = await generateExample(word, translation, sourceLanguage: sourceLanguage);
      
      return {
        'translation': translation,
        'example': example,
      };
    } catch (e) {
      return {
        'translation': 'Çeviri hatası',
        'example': 'Örnek cümle oluşturulamadı - Gemini API gerekli',
      };
    }
  }

  // Get word details with dynamic source and target languages
  Future<Map<String, String>> getWordDetailsWithLanguages(
    String word, {
    String sourceLanguage = 'English',
    String targetLanguage = 'Turkish',
  }) async {
    try {
      String translation;
      
      // If target language is Turkish, use the existing method
      if (targetLanguage == 'Turkish') {
        translation = await translateWord(word);
      } else {
        // Use the language-specific translation method
        translation = await translateWordToLanguage(word, targetLanguage);
      }
      
      // Generate example using Gemini with specified source language
      final example = await generateExample(word, translation, sourceLanguage: sourceLanguage);
      
      return {
        'translation': translation,
        'example': example,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
      };
    } catch (e) {
      return {
        'translation': 'Çeviri hatası',
        'example': 'Örnek cümle oluşturulamadı - Gemini API gerekli',
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
      };
    }
  }

  // Helper method to convert language codes to language names
  String _getLanguageNameFromCode(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return 'English';
      case 'tr':
        return 'Turkish';
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
        return 'English'; // Default fallback
    }
  }

  // Helper method to convert language names to language codes
  String _getLanguageCodeFromName(String languageName) {
    switch (languageName) {
      case 'English':
        return 'en';
      case 'Turkish':
        return 'tr';
      case 'German':
        return 'de';
      case 'French':
        return 'fr';
      case 'Spanish':
        return 'es';
      case 'Italian':
        return 'it';
      case 'Portuguese':
        return 'pt';
      case 'Russian':
        return 'ru';
      case 'Japanese':
        return 'ja';
      case 'Korean':
        return 'ko';
      case 'Chinese':
        return 'zh';
      case 'Arabic':
        return 'ar';
      default:
        return 'en'; // Default fallback
    }
  }

  // Auto-detect source language and get word details
  Future<Map<String, String>> getWordDetailsWithAutoDetection(
    String word, {
    String? sourceLanguageCode, // ISO language code like 'en', 'de', etc.
    String targetLanguage = 'Turkish',
  }) async {
    // Convert language code to language name if provided
    String sourceLanguage = 'English'; // Default
    if (sourceLanguageCode != null) {
      sourceLanguage = _getLanguageNameFromCode(sourceLanguageCode);
    }
    
    try {
      return await getWordDetailsWithLanguages(
        word,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    } catch (e) {
      return {
        'translation': 'Çeviri hatası',
        'example': 'Örnek cümle oluşturulamadı - Gemini API gerekli',
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
      };
    }
  }

  Future<String> _makeRequest(String prompt) async {
    // Check if API key is available and valid
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Gemini API key is not configured. Please set GEMINI_API_KEY in .env file.');
    }

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
          final result = parts[0]['text'] ?? 'No response received';
          return result;
        }
      }
      
      throw Exception('Invalid response format from Gemini API');
    } else if (response.statusCode == 401) {
      throw Exception('Invalid Gemini API key. Please check your GEMINI_API_KEY in .env file.');
    } else if (response.statusCode == 403) {
      throw Exception('Gemini API access denied. Please check your API key permissions.');
    } else if (response.statusCode == 429) {
      throw Exception('Gemini API rate limit exceeded. Please try again later.');
    } else {
      throw Exception('Gemini API request failed: ${response.statusCode} - ${response.body}');
    }
  }
}
