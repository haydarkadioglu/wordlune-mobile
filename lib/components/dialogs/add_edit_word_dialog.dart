import 'package:flutter/material.dart';
import '../../models/list_word.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';

class AddEditWordDialog extends StatefulWidget {
  final String listId;
  final FirestoreService firestoreService;
  final ListWord? existingWord; // null for add, existing word for edit
  final VoidCallback? onSuccess;

  const AddEditWordDialog({
    super.key,
    required this.listId,
    required this.firestoreService,
    this.existingWord,
    this.onSuccess,
  });

  @override
  State<AddEditWordDialog> createState() => _AddEditWordDialogState();
}

class _AddEditWordDialogState extends State<AddEditWordDialog> {
  late final TextEditingController wordController;
  late final TextEditingController meaningController;
  late final TextEditingController exampleController;
  late String selectedLanguage;
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    wordController = TextEditingController(text: widget.existingWord?.word ?? '');
    meaningController = TextEditingController(text: widget.existingWord?.meaning ?? '');
    exampleController = TextEditingController(text: widget.existingWord?.exampleSentence ?? '');
    selectedLanguage = widget.existingWord?.language ?? 'Turkish';
  }

  @override
  void dispose() {
    wordController.dispose();
    meaningController.dispose();
    exampleController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.existingWord != null;

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
                  isEditing ? 'Edit Word' : 'Add New Word',
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
                      controller: wordController,
                      decoration: const InputDecoration(
                        labelText: 'Word',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      autofocus: !isEditing,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: meaningController,
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
                      value: selectedLanguage,
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Turkish', child: Text('Turkish')),
                        DropdownMenuItem(value: 'German', child: Text('German')),
                        DropdownMenuItem(value: 'English', child: Text('English')),
                        DropdownMenuItem(value: 'French', child: Text('French')),
                        DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedLanguage = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: exampleController,
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
                  onPressed: _handleSubmit,
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (wordController.text.trim().isEmpty || meaningController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word and meaning are required')),
      );
      return;
    }
    
    try {
      if (isEditing) {
        final updatedWord = ListWord(
          id: widget.existingWord!.id,
          word: wordController.text.trim(),
          meaning: meaningController.text.trim(),
          exampleSentence: exampleController.text.trim(),
          createdAt: widget.existingWord!.createdAt,
          language: selectedLanguage,
        );
        
        await widget.firestoreService.updateWordInList(
          widget.listId,
          widget.existingWord!.id,
          updatedWord,
        );
      } else {
        final newWord = ListWord(
          id: '',
          word: wordController.text.trim(),
          meaning: meaningController.text.trim(),
          exampleSentence: exampleController.text.trim(),
          createdAt: DateTime.now(),
          language: selectedLanguage,
        );
        
        await widget.firestoreService.addWordToList(
          widget.listId,
          newWord,
        );
      }
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Word ${isEditing ? 'updated' : 'added'} successfully')),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${isEditing ? 'updating' : 'adding'} word: $e')),
        );
      }
    }
  }

  Future<void> _generateAIExplanation() async {
    if (wordController.text.trim().isEmpty) {
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

      // Generate explanation using Gemini
      final explanation = await _geminiService.translateWordToLanguage(
        wordController.text.trim(),
        selectedLanguage,
      );
      
      meaningController.text = explanation;

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI explanation generated with Gemini!'),
            backgroundColor: Colors.purple,
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
          
          // Fallback to basic message
          meaningController.text = 'Translation requires Gemini API';
        }
      }
    }  Future<void> _generateExample() async {
    if (wordController.text.trim().isEmpty || meaningController.text.trim().isEmpty) {
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
        wordController.text.trim(),
        meaningController.text.trim(),
      );
      
      exampleController.text = example;

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
        
        // Fallback to basic message
        exampleController.text = 'Örnek cümle Gemini API ile oluşturulacak...';
      }
    }
  }
}
