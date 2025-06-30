import 'package:flutter/material.dart';
import '../../models/word.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final VoidCallback onTap;
  final Function(String category) onCategoryChanged;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final bool isSelectionMode;
  final bool isSelected;
  final Function(Word, bool)? onSelectionChanged;

  const WordCard({
    super.key,
    required this.word,
    required this.onTap,
    required this.onCategoryChanged,
    required this.onDelete,
    this.onEdit,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isSelectionMode 
            ? () => onSelectionChanged?.call(word, !isSelected)
            : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon and word
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(word.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(word.category),
                          color: _getCategoryColor(word.category),
                          size: 16,
                        ),
                      ),
                      const Spacer(),
                      if (!isSelectionMode)
                        PopupMenuButton<String>(
                    onSelected: (value) {
                      if (['Very Good', 'Good', 'Bad'].contains(value)) {
                        onCategoryChanged(value);
                      } else if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'Very Good',
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Text('Very Good'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'Good',
                        child: Row(
                          children: [
                            Icon(Icons.thumb_up, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Text('Good'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'Bad',
                        child: Row(
                          children: [
                            Icon(Icons.thumb_down, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Bad'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Word text
              Text(
                word.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Meaning
              Text(
                word.meaning,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Example sentence (if available)
              if (word.exampleSentence.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    word.exampleSentence,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
              const Spacer(),
              
              // Date
              Text(
                '${word.dateAdded.day}/${word.dateAdded.month}/${word.dateAdded.year}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
              ),
              
              // Selection checkbox overlay
              if (isSelectionMode)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) => onSelectionChanged?.call(word, value ?? false),
                  ),
                ),
            ],
          ),
        ),
      ),
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
