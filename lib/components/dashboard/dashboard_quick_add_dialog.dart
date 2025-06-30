import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class DashboardQuickAddDialog extends StatefulWidget {
  final FirestoreService firestoreService;

  const DashboardQuickAddDialog({
    super.key,
    required this.firestoreService,
  });

  @override
  State<DashboardQuickAddDialog> createState() => _DashboardQuickAddDialogState();
}

class _DashboardQuickAddDialogState extends State<DashboardQuickAddDialog> {
  final _wordController = TextEditingController();
  String _selectedCategory = 'Good';
  bool _isLoading = false;

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick Add Word'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _wordController,
            decoration: const InputDecoration(
              labelText: 'Word (English)',
              border: OutlineInputBorder(),
              hintText: 'e.g., apple, house, beautiful',
            ),
            autofocus: true,
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
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addWord,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Word'),
        ),
      ],
    );
  }

  Future<void> _addWord() async {
    if (_wordController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      await widget.firestoreService.addWord(
        _wordController.text.trim(),
        category: _selectedCategory,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Word "${_wordController.text}" added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding word: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
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
        return Icons.help_outline;
    }
  }

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
}
