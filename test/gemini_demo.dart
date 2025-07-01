import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wordlune_mobile/services/gemini_service.dart';

void main() {
  group('Gemini AI Creative Examples', () {
    late GeminiService geminiService;

    setUpAll(() async {
      await dotenv.load(fileName: '.env');
    });

    setUp(() {
      geminiService = GeminiService();
    });

    test('demonstrates basic fallback examples (Gemini API unavailable)', () async {
      print('\n🔄 BASIC FALLBACK EXAMPLES (when Gemini API is not available):');
      
      // Test different words with basic fallback
      final words = ['meeting', 'book', 'beautiful', 'run', 'house'];
      final meanings = ['toplantı', 'kitap', 'güzel', 'koşmak', 'ev'];
      
      for (int i = 0; i < words.length; i++) {
        final example = await geminiService.generateExample(words[i], meanings[i]);
        print('${i + 1}. ${words[i]} → $example');
        expect(example, contains(words[i]));
      }
      
      print('\n✅ Fallback system works correctly - provides basic but functional examples');
      print('🚀 For creative examples, configure GEMINI_API_KEY in .env file!');
    });
  });
}
