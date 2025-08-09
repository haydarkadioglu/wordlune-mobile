import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/word.dart';

class BulkAddScreen extends StatefulWidget {
  const BulkAddScreen({super.key});

  @override
  State<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _BulkAddScreenState extends State<BulkAddScreen> {
  final _textController = TextEditingController();
  final _firestoreService = FirestoreService();
  
  String _selectedCategory = 'Good';
  bool _loading = false;
  int _processedCount = 0;
  List<String> _previewWords = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Add Words'),
        actions: [
          if (_previewWords.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructionsCard(),
                  const SizedBox(height: 12),
                  _buildInputCard(),
                  const SizedBox(height: 12),
                  _buildSettingsCard(),
                  if (_previewWords.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildPreviewCard(),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
            ),
            child: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'How to use Bulk Add',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionItem('1.', 'Enter multiple words separated by commas'),
            _buildInstructionItem('2.', 'AI will translate each word and generate examples'),
            _buildInstructionItem('3.', 'Choose a category for your words'),
            _buildInstructionItem('4.', 'Review preview and add to collection with AI content'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Words',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'apple, orange, banana, computer, house...',
                border: OutlineInputBorder(),
                helperText: 'Separate words with commas',
              ),
              maxLines: 4,
              onChanged: _updatePreview,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category for all words',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: ['Very Good', 'Good', 'Bad'].map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(_getCategoryIcon(category), color: _getCategoryColor(category)),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preview (${_previewWords.length} words)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _previewWords.map((word) {
                    return Chip(
                      label: Text(word),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeWord(word),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _previewWords.isNotEmpty && !_loading ? _bulkAddWords : null,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.add_circle),
            label: Text(_loading 
              ? 'Processing ${_processedCount}/${_previewWords.length} words...' 
              : 'Add ${_previewWords.length} Words with AI Examples'
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _clearAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Clear All'),
          ),
        ),
      ],
    );
  }

  void _updatePreview(String text) {
    final words = text
        .split(',')
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toSet() // Remove duplicates
        .toList();
    
    setState(() => _previewWords = words);
  }

  void _removeWord(String word) {
    setState(() {
      _previewWords.remove(word);
      // Update text controller
      _textController.text = _previewWords.join(', ');
    });
  }

  void _clearAll() {
    setState(() {
      _previewWords.clear();
      _textController.clear();
    });
  }

  void _bulkAddWords() async {
    if (_previewWords.isEmpty) return;

    setState(() {
      _loading = true;
      _processedCount = 0;
    });

    try {
      // Process words one by one to show progress
      for (int i = 0; i < _previewWords.length; i++) {
        setState(() => _processedCount = i + 1);
        
        // Add to personal words with category
        final word = Word(
          id: '',
          text: _previewWords[i],
          meaning: '',
          pronunciationText: '',
          exampleSentence: '',
          category: _selectedCategory,
          dateAdded: DateTime.now(),
          language: 'Turkish',
        );
        
        await _firestoreService.addWord(word);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added ${_previewWords.length} words with AI translations and examples!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      _clearAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding words: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
        _processedCount = 0;
      });
    }
  }

  // No list creation functionality needed

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Very Good':
        return Colors.green;
      case 'Good':
        return Colors.orange;
      case 'Bad':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Very Good':
        return Icons.star;
      case 'Good':
        return Icons.thumb_up;
      case 'Bad':
        return Icons.thumb_down;
      default:
        return Icons.help;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
