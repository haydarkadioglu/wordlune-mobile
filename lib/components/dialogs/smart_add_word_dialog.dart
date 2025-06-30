import 'package:flutter/material.dart';
import '../../services/gemini_service.dart';
import '../../services/translation_service.dart';

class SmartAddWordDialog extends StatefulWidget {
  final String listName;
  final Function(String word, String meaning, String example) onWordAdded;

  const SmartAddWordDialog({
    super.key,
    required this.listName,
    required this.onWordAdded,
  });

  @override
  State<SmartAddWordDialog> createState() => _SmartAddWordDialogState();
}

class _SmartAddWordDialogState extends State<SmartAddWordDialog> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  
  bool _isTranslating = false;
  bool _isGeneratingExample = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Word to "${widget.listName}"'),
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
              ),
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 16),
            
            // Meaning input with translate button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _meaningController,
                    decoration: const InputDecoration(
                      labelText: 'Meaning *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., toplantı',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isTranslating ? null : _translateWord,
                    icon: _isTranslating 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.translate, size: 18),
                    label: const Text('Çevir'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Example input with AI generation button
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _exampleController,
                        decoration: const InputDecoration(
                          labelText: 'Example (optional)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., We have a meeting at 3 PM',
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingExample ? null : _generateExample,
                        icon: _isGeneratingExample 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('AI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: (_isTranslating || _isGeneratingExample) ? null : _getFullWordDetails,
                  icon: (_isTranslating || _isGeneratingExample)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.psychology, size: 18),
                  label: const Text('Get Translation + Example'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canSave() ? _saveWord : null,
          child: const Text('Add'),
        ),
      ],
    );
  }

  bool _canSave() {
    return _wordController.text.trim().isNotEmpty && 
           _meaningController.text.trim().isNotEmpty &&
           !_isTranslating && 
           !_isGeneratingExample;
  }

  Future<void> _translateWord() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      _showSnackBar('Please enter a word first', Colors.orange);
      return;
    }

    setState(() => _isTranslating = true);
    
    try {
      // Use Google Translate instead of Gemini for meaning
      final translation = await TranslationService.translateToTurkish(word);
      if (mounted) {
        _meaningController.text = translation;
        
        // Show translation status
        final status = TranslationService.translationStatus;
        _showSnackBar('Çeviri tamamlandı ($status)', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Çeviri başarısız: ${e.toString().replaceAll('Exception: ', '')}', Colors.red);
        
        // Provide manual input option
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Çeviri Hatası'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Otomatik çeviri yapılamadı. Lütfen anlamı manuel olarak girin.'),
                const SizedBox(height: 16),
                Text('Kelime: $word', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTranslating = false);
      }
    }
  }

  Future<void> _generateExample() async {
    final word = _wordController.text.trim();
    final meaning = _meaningController.text.trim();
    
    if (word.isEmpty) {
      _showSnackBar('Please enter a word first', Colors.orange);
      return;
    }
    
    if (meaning.isEmpty) {
      _showSnackBar('Please enter a meaning first', Colors.orange);
      return;
    }

    setState(() => _isGeneratingExample = true);
    
    try {
      final example = await _geminiService.generateExample(word, meaning);
      if (mounted) {
        _exampleController.text = example;
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Example generation failed: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingExample = false);
      }
    }
  }

  Future<void> _getFullWordDetails() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      _showSnackBar('Please enter a word first', Colors.orange);
      return;
    }

    setState(() {
      _isTranslating = true;
      _isGeneratingExample = true;
    });
    
    try {
      // Use Google Translate for meaning and Gemini for example
      final translation = await TranslationService.translateToTurkish(word);
      final example = await _geminiService.generateExample(word, translation);
      
      if (mounted) {
        _meaningController.text = translation;
        _exampleController.text = example;
        
        // Show success with service status
        final status = TranslationService.translationStatus;
        _showSnackBar('Tüm detaylar hazırlandı ($status)', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        _showSnackBar('AI işleme hatası: $errorMsg', Colors.red);
        
        // Show helper dialog for manual input
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Otomatik İşleme Hatası'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Otomatik çeviri ve örnek cümle oluşturulamadı.'),
                const SizedBox(height: 10),
                const Text('Lütfen anlamı ve örnek cümleyi manuel olarak girin.'),
                const SizedBox(height: 16),
                Text('Kelime: $word', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Çeviri Servisi: ${TranslationService.translationStatus}', 
                     style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _isGeneratingExample = false;
        });
      }
    }
  }

  Future<void> _saveWord() async {
    try {
      await widget.onWordAdded(
        _wordController.text.trim(),
        _meaningController.text.trim(),
        _exampleController.text.trim(),
      );
      
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Word "${_wordController.text}" added to list!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error adding word: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    super.dispose();
  }
}
