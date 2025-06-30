import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class BulkAddDialog extends StatefulWidget {
  final String listId;
  final FirestoreService firestoreService;
  final VoidCallback? onSuccess;

  const BulkAddDialog({
    super.key,
    required this.listId,
    required this.firestoreService,
    this.onSuccess,
  });

  @override
  State<BulkAddDialog> createState() => _BulkAddDialogState();
}

class _BulkAddDialogState extends State<BulkAddDialog> {
  final TextEditingController textController = TextEditingController();
  String selectedLanguage = 'German';

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Add Words'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),
            const Text(
              'Enter one word per line, with word and meaning separated by colon or dash:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'Example:\napple: a red fruit\nbook - something to read',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter words and meanings...',
              ),
              minLines: 5,
              maxLines: 8,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    final text = textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some words')),
      );
      return;
    }
    
    final lines = text.split('\n');
    final words = <Map<String, dynamic>>[];
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      String word = '';
      String meaning = '';
      
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          word = parts[0].trim();
          meaning = parts.sublist(1).join(':').trim();
        }
      } else if (line.contains('-')) {
        final parts = line.split('-');
        if (parts.length >= 2) {
          word = parts[0].trim();
          meaning = parts.sublist(1).join('-').trim();
        }
      }
      
      if (word.isNotEmpty && meaning.isNotEmpty) {
        words.add({
          'word': word,
          'meaning': meaning,
          'example': '',
          'language': selectedLanguage,
        });
      }
    }
    
    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid words found')),
      );
      return;
    }
    
    try {
      await widget.firestoreService.addBulkWordsToList(
        listId: widget.listId,
        words: words,
      );
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${words.length} words added successfully')),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding words: $e')),
        );
      }
    }
  }
}
