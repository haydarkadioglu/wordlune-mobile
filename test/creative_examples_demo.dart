import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wordlune_mobile/services/gemini_service.dart';

void main() {
  group('Creative Example Generation Demo', () {
    late GeminiService geminiService;

    setUpAll(() async {
      await dotenv.load(fileName: '.env');
    });

    setUp(() {
      geminiService = GeminiService();
    });

    test('should demonstrate variety in verb examples', () async {
      print('\n🏃‍♂️ VERB EXAMPLES for "run" (koşmak):');
      final examples = <String>{};
      
      for (int i = 0; i < 8; i++) {
        final example = await geminiService.generateExample('run', 'koşmak');
        examples.add(example);
        print('${i + 1}. $example');
        await Future.delayed(const Duration(milliseconds: 15));
      }
      
      print('Generated ${examples.length} unique examples out of 8 attempts');
      expect(examples.length, greaterThan(3));
    });

    test('should demonstrate variety in noun examples', () async {
      print('\n🚗 NOUN EXAMPLES for "car" (araba):');
      final examples = <String>{};
      
      for (int i = 0; i < 8; i++) {
        final example = await geminiService.generateExample('car', 'araba');
        examples.add(example);
        print('${i + 1}. $example');
        await Future.delayed(const Duration(milliseconds: 15));
      }
      
      print('Generated ${examples.length} unique examples out of 8 attempts');
      expect(examples.length, greaterThan(3));
    });

    test('should demonstrate variety in adjective examples', () async {
      print('\n😍 ADJECTIVE EXAMPLES for "beautiful" (güzel):');
      final examples = <String>{};
      
      for (int i = 0; i < 8; i++) {
        final example = await geminiService.generateExample('beautiful', 'güzel');
        examples.add(example);
        print('${i + 1}. $example');
        await Future.delayed(const Duration(milliseconds: 15));
      }
      
      print('Generated ${examples.length} unique examples out of 8 attempts');
      expect(examples.length, greaterThan(3));
    });

    test('should demonstrate contextual examples based on meaning', () async {
      print('\n🍎 CONTEXTUAL EXAMPLES:');
      
      // Food context
      final foodExample = await geminiService.generateExample('apple', 'elma yemek');
      print('Food context (apple + "elma yemek"): $foodExample');
      
      // Home context
      final homeExample = await geminiService.generateExample('house', 'ev');
      print('Home context (house + "ev"): $homeExample');
      
      // Work context
      final workExample = await geminiService.generateExample('work', 'çalışmak');
      print('Work context (work + "çalışmak"): $workExample');
      
      // School context
      final schoolExample = await geminiService.generateExample('school', 'okul');
      print('School context (school + "okul"): $schoolExample');
      
      print('\n✅ All contextual examples generated successfully!');
    });
  });
}
