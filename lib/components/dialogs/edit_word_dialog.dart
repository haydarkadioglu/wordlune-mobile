import 'package:flutter/material.dart';
import '../../models/word.dart';
import '../../services/firestore_service.dart';
import '../../services/translation_service.dart';
import '../../services/gemini_service.dart';

class EditWordDialog extends StatefulWidget {
  final Word word;
  final Function(Word) onWordUpdated;

  const EditWordDialog({
    super.key,
    required this.word,
    required this.onWordUpdated,
  });

  @override
  State<EditWordDialog> createState() => _EditWordDialogState();
}

class _EditWordDialogState extends State<EditWordDialog> {
  late final TextEditingController _wordController;
  late final TextEditingController _meaningController;
  late final TextEditingController _exampleController;
  late String _selectedCategory;
  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.word.text);
    _meaningController = TextEditingController(text: widget.word.meaning);
    _exampleController = TextEditingController(text: widget.word.example ?? '');
    _selectedCategory = widget.word.category;
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Word',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _wordController,
                      decoration: const InputDecoration(
                        labelText: 'Word',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _meaningController,
                            decoration: const InputDecoration(
                              labelText: 'Meaning',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _generateAIExplanation,
                          icon: const Icon(Icons.psychology),
                          tooltip: 'AI Explanation',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.purple.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Very Good',
                          child: Row(
                            children: [
                              Icon(Icons.star, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('Very Good'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Good',
                          child: Row(
                            children: [
                              Icon(Icons.thumb_up, color: Colors.orange, size: 16),
                              SizedBox(width: 8),
                              Text('Good'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Bad',
                          child: Row(
                            children: [
                              Icon(Icons.thumb_down, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Text('Bad'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _exampleController,
                            decoration: const InputDecoration(
                              labelText: 'Example (Optional)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _generateExample,
                          icon: const Icon(Icons.auto_awesome),
                          tooltip: 'Generate Example with Gemini',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAIExplanation() async {
    if (_wordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a word first')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating explanation with Gemini AI...'),
            ],
          ),
        ),
      );

      // Use Google Translate for meaning instead of generating explanation
      final translation = await TranslationService.translateToTurkish(_wordController.text.trim());
      
      _meaningController.text = translation;

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Translation completed with Google Translate!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI explanation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Fallback to mock explanation
        final mockExplanation = _getMockAIExplanation(_wordController.text.trim());
        _meaningController.text = mockExplanation;
      }
    }
  }

  Future<void> _generateExample() async {
    if (_wordController.text.trim().isEmpty || _meaningController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter word and meaning first')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating example with Gemini AI...'),
            ],
          ),
        ),
      );

      // Generate example using Gemini
      final example = await _geminiService.generateExample(
        _wordController.text.trim(),
        _meaningController.text.trim(),
      );
      
      _exampleController.text = example;

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Example generated with Gemini AI!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Example generation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Fallback to mock example
        _exampleController.text = 'Örnek cümle Gemini API ile oluşturulacak...';
      }
    }
  }

  String _getMockTranslation(String word) {
    // Mock translations - replace with actual translation service
    final translations = {
      'hello': 'merhaba',
      'world': 'dünya',
      'book': 'kitap',
      'house': 'ev',
      'water': 'su',
      'food': 'yemek',
      'love': 'aşk',
      'beautiful': 'güzel',
      'computer': 'bilgisayar',
      'phone': 'telefon',
    };
    
    return translations[word.toLowerCase()] ?? 'Translation not found';
  }

  String _getMockAIExplanation(String word) {
    // Mock AI explanations - replace with actual AI service
    return 'AI-generated explanation for "$word": This is a detailed explanation of the word, its usage, context, and examples.';
  }

  Future<void> _handleSubmit() async {
    if (_wordController.text.trim().isEmpty || _meaningController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word and meaning are required')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await _firestoreService.updateWordDetails(
        widget.word.id,
        text: _wordController.text.trim(),
        meaning: _meaningController.text.trim(),
        example: _exampleController.text.trim().isEmpty ? null : _exampleController.text.trim(),
        category: _selectedCategory,
      );
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Word updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating word: $e')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
