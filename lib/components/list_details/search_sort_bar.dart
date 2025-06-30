import 'package:flutter/material.dart';

enum SortOption { alphabetical, dateAdded, dateAddedReverse }

class SearchSortBar extends StatelessWidget {
  final Function(String) onSearchChanged;
  final Function(SortOption) onSortChanged;
  final SortOption currentSortOption;

  const SearchSortBar({
    super.key,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.currentSortOption,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search words...',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          PopupMenuButton<SortOption>(
            tooltip: 'Sort',
            icon: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 14),
              ],
            ),
            onSelected: onSortChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.alphabetical,
                child: Text('Alphabetical (A-Z)'),
              ),
              const PopupMenuItem(
                value: SortOption.dateAdded,
                child: Text('Newest First'),
              ),
              const PopupMenuItem(
                value: SortOption.dateAddedReverse,
                child: Text('Oldest First'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
