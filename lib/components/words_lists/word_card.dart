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
        onLongPress: !isSelectionMode && (onEdit != null || onDelete != null)
            ? () => _showActionsBottomSheet(context)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 4 : 6),
          child: Stack(
            children: [
              isListView ? _buildListViewLayout(context) : _buildGridViewLayout(context, isSmall),
              
              // Selection checkbox overlay
              if (isSelectionMode)
                Positioned(
                  top: -4,
                  left: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => onSelectionChanged?.call(word, value ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListViewLayout(BuildContext context) {
    return Column(
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
    );
  }

  Widget _buildGridViewLayout(BuildContext context, bool isSmall) {
    return Column(
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
    );
  }

  void _showActionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              word.text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!(word);
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                titleTextStyle: const TextStyle(color: Colors.red),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!(word);
                },
              ),
          ],
        ),
      ),
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
