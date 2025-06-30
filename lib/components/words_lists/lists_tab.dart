import 'package:flutter/material.dart';
import '../../models/word_list.dart';
import '../../services/firestore_service.dart';
import 'list_card.dart';

class ListsTab extends StatelessWidget {
  final String searchQuery;
  final VoidCallback onCreateListPressed;
  final Function(WordList) onListTap;
  final Function(WordList, String) onListMenuSelected;

  const ListsTab({
    super.key,
    required this.searchQuery,
    required this.onCreateListPressed,
    required this.onListTap,
    required this.onListMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<WordList>>(
      stream: firestoreService.getLists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your lists...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading lists: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Retry logic should be handled by parent
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.playlist_add, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No lists found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first list to organize words!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onCreateListPressed,
                  icon: const Icon(Icons.add),
                  label: const Text('Create List'),
                ),
              ],
            ),
          );
        }

        // Filter lists
        List<WordList> filteredLists = snapshot.data!;
        if (searchQuery.isNotEmpty) {
          filteredLists = filteredLists.where((list) =>
            list.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            list.description.toLowerCase().contains(searchQuery.toLowerCase())
          ).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredLists.length,
          itemBuilder: (context, index) {
            final list = filteredLists[index];
            return ListCard(
              list: list,
              onTap: () => onListTap(list),
              onMenuSelected: (value) => onListMenuSelected(list, value),
            );
          },
        );
      },
    );
  }
}
