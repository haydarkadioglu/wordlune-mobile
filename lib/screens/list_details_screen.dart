import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/word_list.dart';
import '../models/list_word.dart';
import '../components/list_details/list_info_card.dart';
import '../components/list_details/search_sort_bar.dart';
import '../components/list_details/word_list_view.dart';
import '../components/dialogs/add_edit_word_dialog.dart';
import '../components/dialogs/bulk_add_dialog.dart';

class WordListDetailsScreen extends StatefulWidget {
  final WordList wordList;

  const WordListDetailsScreen({super.key, required this.wordList});

  @override
  State<WordListDetailsScreen> createState() => _WordListDetailsScreenState();
}

class _WordListDetailsScreenState extends State<WordListDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';
  SortOption _currentSortOption = SortOption.dateAdded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wordList.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditListDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteListDialog();
              } else if (value == 'bulk_add') {
                _showBulkAddDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bulk_add',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline),
                    SizedBox(width: 8),
                    Text('Bulk Add Words'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete List'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWordDialog,
        tooltip: 'Add Word',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // List info card
          ListInfoCard(
            wordList: widget.wordList,
            firestoreService: _firestoreService,
          ),
          
          // Search and Sort Bar
          SearchSortBar(
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
            onSortChanged: (value) {
              setState(() {
                _currentSortOption = value;
              });
            },
            currentSortOption: _currentSortOption,
          ),
          
          // Word list
          Expanded(
            child: WordListView(
              wordList: widget.wordList,
              firestoreService: _firestoreService,
              searchQuery: _searchQuery,
              currentSortOption: _currentSortOption,
              onEditWord: _showEditWordDialog,
              onDeleteWord: _showDeleteWordDialog,
              onAddWord: _showAddWordDialog,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWordDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditWordDialog(
        listId: widget.wordList.id,
        firestoreService: _firestoreService,
      ),
    );
  }

  void _showEditWordDialog(ListWord word) {
    showDialog(
      context: context,
      builder: (context) => AddEditWordDialog(
        listId: widget.wordList.id,
        firestoreService: _firestoreService,
        existingWord: word,
      ),
    );
  }

  void _showDeleteWordDialog(ListWord word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Word'),
        content: Text('Are you sure you want to delete "${word.word}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.deleteWord(word.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Word deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting word: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditListDialog() {
    final nameController = TextEditingController(text: widget.wordList.name);
    final descriptionController = TextEditingController(text: widget.wordList.description);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }
              
              final updatedList = WordList(
                id: widget.wordList.id,
                name: nameController.text.trim(),
                description: descriptionController.text.trim(),
                wordCount: widget.wordList.wordCount,
                createdAt: widget.wordList.createdAt,
                userId: widget.wordList.userId,
              );
              
              try {
                await _firestoreService.updateWordList(updatedList);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('List updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating list: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteListDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text(
          'Are you sure you want to delete "${widget.wordList.name}" and all its words? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              try {
                await _firestoreService.deleteWordList(widget.wordList.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('List deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting list: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Words'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search term',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value.trim().toLowerCase();
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = searchController.text.trim().toLowerCase();
              });
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showBulkAddDialog() {
    showDialog(
      context: context,
      builder: (context) => BulkAddDialog(
        listId: widget.wordList.id,
        firestoreService: _firestoreService,
      ),
    );
  }
}
