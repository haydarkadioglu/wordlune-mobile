import 'package:flutter/material.dart';
import '../../services/gemini_service.dart';
import '../../services/translation_service.dart';

class AddWordDialog extends StatefulWidget {
  final Function(String word, String meaning, String ipa, String example, String category, String language) onWordAdded;

  const AddWordDialog({
    super.key,
    required this.onWordAdded,
  });

  @override
  State<AddWordDialog> createState() => _AddWordDialogState();
}

class _AddWordDialogState extends State<AddWordDialog> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _ipaController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  
  String _selectedCategory = 'Good';
  String _selectedLanguage = 'Turkish';
  bool _isTranslating = false;
  bool _isGeneratingExample = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Word'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Word input
            TextField(
              controller: _wordController,
              decoration: const InputDecoration(
                labelText: 'Word *',
                border: OutlineInputBorder(),
                hintText: 'e.g., meeting',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 12),
            
            // Meaning with AI button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _meaningController,
                    decoration: const InputDecoration(
                      labelText: 'Meaning *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., toplantı',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (_isTranslating || _isGeneratingExample) ? null : _translateWord,
                    icon: _isTranslating 
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.translate, size: 16),
                    label: const Text('Çevir', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Language selection
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'Turkish', child: Text('Turkish')),
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'German', child: Text('German')),
                DropdownMenuItem(value: 'French', child: Text('French')),
                DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            
            // IPA input
            TextField(
              controller: _ipaController,
              decoration: const InputDecoration(
                labelText: 'Pronunciation (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., /ˈmiːtɪŋ/',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            
            // Example with AI button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _exampleController,
                    decoration: const InputDecoration(
                      labelText: 'Example (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., We have a meeting at 3 PM',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  children: [
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: (_isTranslating || _isGeneratingExample) ? null : _generateExample,
                        icon: _isGeneratingExample 
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome, size: 14),
                        label: const Text('AI', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: (_isTranslating || _isGeneratingExample) ? null : _getFullDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: (_isTranslating || _isGeneratingExample) 
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Full', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'Very Good', child: Text('Very Good')),
                DropdownMenuItem(value: 'Good', child: Text('Good')),
                DropdownMenuItem(value: 'Needs Review', child: Text('Needs Review')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isTranslating || _isGeneratingExample) ? null : () {
            if (_wordController.text.trim().isEmpty || _meaningController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Word and meaning are required')),
              );
              return;
            }
            
            widget.onWordAdded(
              _wordController.text.trim(), 
              _meaningController.text.trim(),
              _ipaController.text.trim(), 
              _exampleController.text.trim(), 
              _selectedCategory,
              _selectedLanguage,
            );
            
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
  
  // Use Google Translate for meaning translation
  Future<void> _translateWord() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a word first')),
      );
      return;
    }
    
    setState(() {
      _isTranslating = true;
    });
    
    try {
      final targetLanguageCode = TranslationService.getLanguageCode(_selectedLanguage);
      final translation = await TranslationService.translate(
        text: word,
        targetLanguage: targetLanguageCode,
        sourceLanguage: 'auto',
      );
      
      setState(() {
        _meaningController.text = translation;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation error: $e')),
        );
      }
    }
  }
  
  // Use Gemini API for example generation
  Future<void> _generateExample() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a word first')),
      );
      return;
    }
    
    setState(() {
      _isGeneratingExample = true;
    });
    
    try {
      final example = await _geminiService.generateExample(word, _meaningController.text.trim());
      setState(() {
        _exampleController.text = example;
        _isGeneratingExample = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingExample = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Example generation error: $e')),
        );
      }
    }
  }
  
  // Use both Google Translate (meaning) and Gemini (example) for full details
  Future<void> _getFullDetails() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a word first')),
      );
      return;
    }
    
    setState(() {
      _isTranslating = true;
      _isGeneratingExample = true;
    });
    
    try {
      // Get translation using Google Translate
      final targetLanguageCode = TranslationService.getLanguageCode(_selectedLanguage);
      final translation = await TranslationService.translate(
        text: word,
        targetLanguage: targetLanguageCode,
        sourceLanguage: 'auto',
      );
      
      // Get example using Gemini API
      final example = await _geminiService.generateExample(word, translation);
      
      setState(() {
        _meaningController.text = translation;
        _exampleController.text = example;
        _isTranslating = false;
        _isGeneratingExample = false;
      });
    } catch (e) {
      setState(() {
        _isTranslating = false;
        _isGeneratingExample = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching word details: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _ipaController.dispose();
    _exampleController.dispose();
    super.dispose();
  }
}
