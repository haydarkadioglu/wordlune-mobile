import 'package:flutter/material.dart';
import '../../models/word.dart';

class WordDetailsDialog extends StatelessWidget {
  final Word word;

  const WordDetailsDialog({
    super.key,
    required this.word,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(word.text),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meaning:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(word.meaning),
          
          if (word.ipa.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Pronunciation:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(word.ipa),
          ],
          
          if (word.example.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Example:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              word.example,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _getCategoryIcon(word.category),
                color: _getCategoryColor(word.category),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                word.category,
                style: TextStyle(
                  color: _getCategoryColor(word.category),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
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
}
