import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import '../services/firestore_service.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final _inputController = TextEditingController();
  final _translator = GoogleTranslator();
  final _firestoreService = FirestoreService();
  
  String _fromLanguage = 'en';
  String _toLanguage = 'tr';
  String _translatedText = '';
  bool _isTranslating = false;
  bool _showResult = false;

  final Map<String, String> _languages = {
    'en': 'English',
    'tr': 'Turkish',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'ar': 'Arabic',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildHeader(),
            const SizedBox(height: 16),
            _buildLanguageSelector(),
            const SizedBox(height: 16),
            _buildInputSection(),
            const SizedBox(height: 16),
            if (_showResult) ...[
              _buildResultSection(),
              const SizedBox(height: 16),
            ],
            _buildActionButtons(),
            const SizedBox(height: 20), // Extra bottom padding for safe area
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Quick Translator',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.swap_horiz),
          onPressed: _swapLanguages,
          tooltip: 'Swap languages',
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  DropdownButton<String>(
                    value: _fromLanguage,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: _languages.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _fromLanguage = value!);
                      if (_inputController.text.isNotEmpty) {
                        _translateText();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  DropdownButton<String>(
                    value: _toLanguage,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: _languages.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _toLanguage = value!);
                      if (_inputController.text.isNotEmpty) {
                        _translateText();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enter text to translate',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_inputController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _inputController.clear();
                      setState(() {
                        _translatedText = '';
                        _showResult = false;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'Type or paste text here...',
                border: const OutlineInputBorder(),
                suffixIcon: _inputController.text.isNotEmpty
                    ? IconButton(
                        onPressed: _translateText,
                        icon: _isTranslating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.translate),
                      )
                    : null,
              ),
              maxLines: 4,
              onChanged: (text) {
                setState(() {});
                if (text.trim().isNotEmpty) {
                  _debounceTranslation();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Translation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _copyToClipboard(_translatedText),
                      icon: const Icon(Icons.copy),
                      iconSize: 20,
                      tooltip: 'Copy translation',
                    ),
                    IconButton(
                      onPressed: _addToWordCollection,
                      icon: const Icon(Icons.add),
                      iconSize: 20,
                      tooltip: 'Add to collection',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ),
              child: Text(
                _translatedText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _inputController.text.isNotEmpty ? _translateText : null,
                    icon: _isTranslating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.translate),
                    label: const Text('Translate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showResult ? _addToWordCollection : null,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Add to Collection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _inputController.clear();
                  setState(() {
                    _translatedText = '';
                    _showResult = false;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Clear All'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _swapLanguages() {
    setState(() {
      final temp = _fromLanguage;
      _fromLanguage = _toLanguage;
      _toLanguage = temp;
    });

    if (_showResult) {
      _inputController.text = _translatedText;
      _translateText();
    }
  }

  void _translateText() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() => _isTranslating = true);

    try {
      final translation = await _translator.translate(
        _inputController.text,
        from: _fromLanguage,
        to: _toLanguage,
      );

      setState(() {
        _translatedText = translation.text;
        _showResult = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Translation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isTranslating = false);
    }
  }

  void _debounceTranslation() {
    // Simple debounce - wait for user to stop typing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_inputController.text.trim().isNotEmpty && !_isTranslating) {
        _translateText();
      }
    });
  }

  void _addToWordCollection() {
    if (!_showResult || _translatedText.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AddToCollectionDialog(
        word: _fromLanguage == 'en' ? _inputController.text : _translatedText,
        translation: _fromLanguage == 'en' ? _translatedText : _inputController.text,
        firestoreService: _firestoreService,
      ),
    );
  }

  void _copyToClipboard(String text) {
    // In a real app, you'd use Clipboard.setData
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}

class AddToCollectionDialog extends StatefulWidget {
  final String word;
  final String translation;
  final FirestoreService firestoreService;

  const AddToCollectionDialog({
    super.key,
    required this.word,
    required this.translation,
    required this.firestoreService,
  });

  @override
  State<AddToCollectionDialog> createState() => _AddToCollectionDialogState();
}

class _AddToCollectionDialogState extends State<AddToCollectionDialog> {
  String _selectedCategory = 'Good';
  String _selectedList = '';
  List<String> _lists = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  void _loadLists() {
    widget.firestoreService.getListNames().listen((lists) {
      setState(() => _lists = lists);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to Collection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(widget.word),
            subtitle: Text(widget.translation),
            leading: const Icon(Icons.translate),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: ['Very Good', 'Good', 'Bad'].map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedList.isEmpty ? null : _selectedList,
            decoration: const InputDecoration(
              labelText: 'Word List (Optional)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('No list')),
              ..._lists.map((list) {
                return DropdownMenuItem(value: list, child: Text(list));
              }),
            ],
            onChanged: (value) => setState(() => _selectedList = value ?? ''),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _addWord,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  void _addWord() async {
    setState(() => _loading = true);

    try {
      await widget.firestoreService.addWordWithDetails(
        word: widget.word,
        translation: widget.translation,
        ipa: '',
        example: '',
        category: _selectedCategory,
        listId: _selectedList.isNotEmpty ? _selectedList : null,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word added to collection!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding word: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
}
