import 'package:flutter/material.dart';
import '../../models/word.dart';
import '../../services/firestore_service.dart';
import '../dialogs/edit_word_dialog.dart';
import 'word_card.dart';
import '../../enums/view_mode.dart';

class WordsTab extends StatefulWidget {
  final String searchQuery;
  final String selectedCategory;
  final ViewMode viewMode;
  final VoidCallback onAddWordPressed;
  final Function(Word) onWordTap;
  final VoidCallback onCategoryCleared;

  const WordsTab({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    required this.viewMode,
    required this.onAddWordPressed,
    required this.onWordTap,
    required this.onCategoryCleared,
  });

  @override
  State<WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends State<WordsTab> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSelectionMode = false;
  Set<String> _selectedWords = {};

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Column(
      children: [
        // Selection mode header
        if (_isSelectionMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedWords.clear();
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    '${_selectedWords.length} selected',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (_selectedWords.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteSelectedWords,
                  ),
              ],
            ),
          ),
        
        // Bulk action button (when not in selection mode)
        if (!_isSelectionMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.checklist, size: 18),
                  label: const Text('Select'),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = true;
                    });
                  },
                ),
              ],
            ),
          ),
        
        // Category filter chips
        if (widget.selectedCategory.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Chip(
                  label: Text(widget.selectedCategory),
                  backgroundColor: _getCategoryColor(widget.selectedCategory).withOpacity(0.2),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: widget.onCategoryCleared,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        
        // Words content
        Expanded(
          child: StreamBuilder<List<Word>>(
            stream: firestoreService.getWords(),
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
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading words: ${snapshot.error}'),
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
                      Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No words found',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first word to get started!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: widget.onAddWordPressed,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Word'),
                      ),
                    ],
                  ),
                );
              }

              // Filter words
              List<Word> filteredWords = snapshot.data!;
              
              if (widget.searchQuery.isNotEmpty) {
                filteredWords = filteredWords.where((word) =>
                  word.text.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
                  word.meaning.toLowerCase().contains(widget.searchQuery.toLowerCase())
                ).toList();
              }
              
              if (widget.selectedCategory.isNotEmpty) {
                filteredWords = filteredWords.where((word) => word.category == widget.selectedCategory).toList();
              }

              return _buildWordsView(filteredWords);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWordsView(List<Word> words) {
    switch (widget.viewMode) {
      case ViewMode.list:
        return _buildWordsList(words);
      case ViewMode.grid3:
        return _buildWordsGrid(words, 3);
      case ViewMode.grid4:
        return _buildWordsGrid(words, 4);
    }
  }

  Widget _buildWordsList(List<Word> words) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: WordCard(
            word: word,
            columns: 1, // List view uses single column
            onTap: () => widget.onWordTap(word),
            onEdit: _editWord,
            onDelete: _deleteWord,
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedWords.contains(word.id),
            onSelectionChanged: _onSelectionChanged,
          ),
        );
      },
    );
  }

  Widget _buildWordsGrid(List<Word> words, int columns) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: columns == 4 ? 0.85 : 0.8,
      ),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return WordCard(
          word: word,
          columns: columns,
          onTap: () => widget.onWordTap(word),
          onEdit: _editWord,
          onDelete: _deleteWord,
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedWords.contains(word.id),
          onSelectionChanged: _onSelectionChanged,
        );
      },
    );
  }

  void _editWord(Word word) {
    showDialog(
      context: context,
      builder: (context) => EditWordDialog(
        word: word,
        onWordUpdated: (updatedWord) {
          // The StreamBuilder will automatically update when Firestore changes
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Word "${updatedWord.text}" updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _deleteWord(Word word) {
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
                    SnackBar(
                      content: Text('Word "${word.text}" deleted successfully!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting word: $e'),
                      backgroundColor: Colors.red,
                    ),
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

  void _onSelectionChanged(Word word, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedWords.add(word.id);
      } else {
        _selectedWords.remove(word.id);
      }
    });
  }

  void _deleteSelectedWords() {
    if (_selectedWords.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Words'),
        content: Text('Are you sure you want to delete ${_selectedWords.length} selected words?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Deleting words...'),
                    ],
                  ),
                ),
              );
              
              try {
                // Delete all selected words
                for (String wordId in _selectedWords) {
                  await _firestoreService.deleteWord(wordId);
                }
                
                if (mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_selectedWords.length} words deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Exit selection mode
                  setState(() {
                    _isSelectionMode = false;
                    _selectedWords.clear();
                  });
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting words: $e'),
                      backgroundColor: Colors.red,
                    ),
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
