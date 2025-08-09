import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/word.dart';
import '../components/words/empty_words_state.dart';
import '../components/words/word_card.dart';
import '../components/words/category_filter_bar.dart';
import '../components/dialogs/word_details_dialog.dart';
import '../components/dialogs/add_word_dialog.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';
  String _selectedCategory = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Words'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWordDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedCategory = value);
            },
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
            ],
            child: Icon(_selectedCategory.isEmpty ? Icons.filter_list : Icons.filter_alt),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          CategoryFilterBar(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (category) {
              setState(() => _selectedCategory = category);
            },
          ),
          
          // Words grid
          Expanded(
            child: StreamBuilder<List<Word>>(
              stream: _firestoreService.getWords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your words...'),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('Error loading words: ${snapshot.error}'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return EmptyWordsState(onAddWord: _showAddWordDialog);
                }
                
                var words = snapshot.data!;
                
                // Apply filters
                if (_selectedCategory.isNotEmpty) {
                  words = words.where((word) => word.category == _selectedCategory).toList();
                }
                
                if (_searchQuery.isNotEmpty) {
                  words = words.where((word) =>
                    word.text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    word.meaning.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                if (words.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_searchQuery.isNotEmpty 
                          ? 'No words match your search' 
                          : 'No words in this category'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _searchQuery = '';
                            _selectedCategory = '';
                          }),
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  );
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    final word = words[index];
                    return WordCard(
                      word: word,
                      onTap: () => _showWordDetails(word),
                      onCategoryChanged: (category) => _updateWordCategory(word, category),
                      onDelete: () => _showDeleteDialog(word),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showWordDetails(Word word) {
    showDialog(
      context: context,
      builder: (context) => WordDetailsDialog(word: word),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController(text: _searchQuery);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Words'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Enter word or meaning...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            setState(() => _searchQuery = value.trim().toLowerCase());
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = searchController.text.trim().toLowerCase());
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showAddWordDialog() {
    showDialog(
      context: context,
      builder: (context) => AddWordDialog(
        onWordAdded: (word, meaning, ipa, example, category, language) async {
          await _firestoreService.addWordWithDetails(
            word,
            meaning,
            ipa,
            category,  // partOfSpeech
            example,
            'medium',  // difficulty
          );
        },
      ),
    );
  }

  Future<void> _updateWordCategory(Word word, String category) async {
    try {
      await _firestoreService.updateWordCategory(word.id, category);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Word category updated to $category')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating category: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(Word word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Word'),
        content: Text('Are you sure you want to delete "${word.text}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.deleteWord(word.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Word "${word.text}" deleted!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting word: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
