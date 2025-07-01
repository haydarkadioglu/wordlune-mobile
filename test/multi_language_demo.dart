import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wordlune_mobile/services/gemini_service.dart';

void main() async {
  print('🌐 Multi-Language GeminiService Demo');
  print('=====================================\n');
  
  // Initialize dotenv
  await dotenv.load(fileName: '.env');
  
  final geminiService = GeminiService();
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  
  if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
    print('❌ No valid Gemini API key found. Skipping demo.');
    return;
  }
  
  print('✅ Gemini API key found. Running multi-language demo...\n');
  
  // Test different languages
  final testWords = [
    {'word': 'freedom', 'language': 'English'},
    {'word': 'Freiheit', 'language': 'German'},
    {'word': 'liberté', 'language': 'French'},
    {'word': 'libertad', 'language': 'Spanish'},
    {'word': 'özgürlük', 'language': 'Turkish'},
  ];
  
  for (final testWord in testWords) {
    try {
      print('🔍 Testing: "${testWord['word']}" (${testWord['language']})');
      
      final details = await geminiService.getWordDetailsWithLanguages(
        testWord['word']!,
        sourceLanguage: testWord['language']!,
        targetLanguage: 'Turkish',
      );
      
      print('   📝 Example: ${details['example']}');
      print('   🔄 Translation: ${details['translation']}');
      print('   🌍 Source: ${details['sourceLanguage']} → Target: ${details['targetLanguage']}');
      print('');
      
    } catch (e) {
      print('   ❌ Error: $e');
      print('');
    }
  }
  
  // Test auto-detection with language codes
  print('🤖 Testing auto-detection with language codes...\n');
  
  final autoDetectTests = [
    {'word': 'amore', 'code': 'it'}, // Italian
    {'word': 'любовь', 'code': 'ru'}, // Russian
    {'word': '愛', 'code': 'zh'}, // Chinese
  ];
  
  for (final test in autoDetectTests) {
    try {
      print('🔍 Auto-detecting: "${test['word']}" (code: ${test['code']})');
      
      final details = await geminiService.getWordDetailsWithAutoDetection(
        test['word']!,
        sourceLanguageCode: test['code']!,
        targetLanguage: 'Turkish',
      );
      
      print('   📝 Example: ${details['example']}');
      print('   🔄 Translation: ${details['translation']}');
      print('   🌍 Detected Source: ${details['sourceLanguage']}');
      print('');
      
    } catch (e) {
      print('   ❌ Error: $e');
      print('');
    }
  }
  
  print('🎉 Multi-language demo completed!');
}
