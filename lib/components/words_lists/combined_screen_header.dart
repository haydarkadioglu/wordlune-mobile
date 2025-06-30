import 'package:flutter/material.dart';
import '../../enums/view_mode.dart';

class CombinedScreenHeader extends StatelessWidget {
  final TabController tabController;
  final ViewMode viewMode;
  final String selectedCategory;
  final VoidCallback onSearchPressed;
  final VoidCallback onAddPressed;
  final Function(ViewMode) onViewModeChanged;
  final Function(String) onCategoryChanged;

  const CombinedScreenHeader({
    super.key,
    required this.tabController,
    required this.viewMode,
    required this.selectedCategory,
    required this.onSearchPressed,
    required this.onAddPressed,
    required this.onViewModeChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 40, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black12 : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'My Collection',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearchPressed,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onAddPressed,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          if (tabController.index == 0) ...[
            PopupMenuButton<ViewMode>(
              icon: Icon(Icons.view_module, color: isDarkMode ? Colors.white70 : Colors.black54),
              onSelected: onViewModeChanged,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: ViewMode.list,
                  child: Row(
                    children: [
                      Icon(Icons.list, size: 16),
                      SizedBox(width: 8),
                      Text('List View'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ViewMode.grid3,
                  child: Row(
                    children: [
                      Icon(Icons.grid_3x3, size: 16),
                      SizedBox(width: 8),
                      Text('3 Column Grid'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ViewMode.grid4,
                  child: Row(
                    children: [
                      Icon(Icons.grid_4x4, size: 16),
                      SizedBox(width: 8),
                      Text('4 Column Grid'),
                    ],
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.category, color: isDarkMode ? Colors.white70 : Colors.black54),
              onSelected: onCategoryChanged,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: '',
                  child: Text('All Categories'),
                ),
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
                      Icon(Icons.check_circle, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text('Good'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'Bad',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('Bad'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
