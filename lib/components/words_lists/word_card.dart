import 'package:flutter/material.dart';
import '../../models/word.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final int columns;
  final VoidCallback onTap;
  final Function(Word)? onEdit;
  final Function(Word)? onDelete;
  final bool isSelectionMode;
  final bool isSelected;
  final Function(Word, bool)? onSelectionChanged;

  const WordCard({
    super.key,
    required this.word,
    required this.columns,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = columns == 4;
    final isListView = columns == 1;
    
    return Card(
      elevation: 2,
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: isSelectionMode 
            ? () => onSelectionChanged?.call(word, !isSelected)
            : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 6 : 8),
          child: Stack(
            children: [
              isListView ? _buildListViewLayout(context) : _buildGridViewLayout(context, isSmall),
              
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

  Widget _buildListViewLayout(BuildContext context) {
    return Row(
      children: [
        // Word content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                word.meaning,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Example sentence (if available)
              if (word.exampleSentence.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    word.exampleSentence,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCategoryColor(word.category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  word.category,
                  style: TextStyle(
                    color: _getCategoryColor(word.category),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Three-dot menu for list view
        if (!isSelectionMode && (onEdit != null || onDelete != null))
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              if (value == 'edit' && onEdit != null) {
                onEdit!(word);
              } else if (value == 'delete' && onDelete != null) {
                onDelete!(word);
              }
            },
            itemBuilder: (context) => [
              if (onEdit != null)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
              if (onDelete != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildGridViewLayout(BuildContext context, bool isSmall) {
    return Stack(
      children: [
        // Main content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    word.text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmall ? 14 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: isSmall ? 6 : 8,
                  height: isSmall ? 6 : 8,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(word.category),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 4 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.meaning,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isSmall ? 12 : 14,
                    ),
                    maxLines: isSmall ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Example sentence (if available and not small)
                  if (word.exampleSentence.isNotEmpty && !isSmall) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        word.exampleSentence,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isSmall) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCategoryColor(word.category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  word.category,
                  style: TextStyle(
                    color: _getCategoryColor(word.category),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        // Action buttons for grid view (overlay)
        if (!isSelectionMode && (onEdit != null || onDelete != null))
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: isSmall ? 16 : 18,
                color: Colors.grey[600],
              ),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'edit' && onEdit != null) {
                  onEdit!(word);
                } else if (value == 'delete' && onDelete != null) {
                  onDelete!(word);
                }
              },
            ),
          ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'business':
        return Colors.blue;
      case 'technology':
        return Colors.green;
      case 'science':
        return Colors.purple;
      case 'education':
        return Colors.orange;
      case 'health':
        return Colors.red;
      case 'travel':
        return Colors.teal;
      case 'sports':
        return Colors.indigo;
      case 'entertainment':
        return Colors.pink;
      case 'food':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
