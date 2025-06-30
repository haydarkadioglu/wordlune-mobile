import 'package:flutter/material.dart';

class CategoryFilterBar extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCategory.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Chip(
            label: Text(selectedCategory),
            backgroundColor: _getCategoryColor(selectedCategory).withOpacity(0.2),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => onCategoryChanged(''),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
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
}
