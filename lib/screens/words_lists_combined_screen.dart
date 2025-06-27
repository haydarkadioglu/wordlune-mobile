import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/word.dart';
import '../models/word_list.dart';
import 'list_details_screen.dart';

class WordsListsCombinedScreen extends StatefulWidget {
  const WordsListsCombinedScreen({super.key});

  @override
  State<WordsListsCombinedScreen> createState() => _WordsListsCombinedScreenState();
}

class _WordsListsCombinedScreenState extends State<WordsListsCombinedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  
  // Words tab state
  String _wordsSearchQuery = '';
  String _selectedCategory = '';
  ViewMode _viewMode = ViewMode.grid3;
  
  // Lists tab state
  String _listsSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Column(
        children: [
          // Custom header with proper spacing and color
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
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
                  onPressed: _showSearchDialog,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _tabController.index == 0 ? _showAddWordDialog : _showCreateListDialog,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                if (_tabController.index == 0)
                  PopupMenuButton<ViewMode>(
                    icon: Icon(Icons.view_module, color: isDarkMode ? Colors.white70 : Colors.black54),
                    onSelected: (mode) => setState(() => _viewMode = mode),
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
                if (_tabController.index == 0)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.category, color: isDarkMode ? Colors.white70 : Colors.black54),
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
            ),
          ),
          // Tab bar with improved visibility
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: isDarkMode ? Colors.white60 : Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              onTap: (index) => setState(() {}),
              tabs: const [
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_rounded),
                        SizedBox(width: 8),
                        Text('Words'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.view_list_rounded),
                        SizedBox(width: 8),
                        Text('Lists'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWordsTab(),
                _buildListsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordsTab() {
    return Column(
      children: [
        // Category filter chips
        if (_selectedCategory.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Chip(
                  label: Text(_selectedCategory),
                  backgroundColor: _getCategoryColor(_selectedCategory).withOpacity(0.2),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => setState(() => _selectedCategory = ''),
                ),
              ],
            ),
          ),
        
        // Words content
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
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading words: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
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
                        onPressed: _showAddWordDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Word'),
                      ),
                    ],
                  ),
                );
              }

              // Filter words
              List<Word> filteredWords = snapshot.data!;
              
              if (_wordsSearchQuery.isNotEmpty) {
                filteredWords = filteredWords.where((word) =>
                  word.text.toLowerCase().contains(_wordsSearchQuery.toLowerCase()) ||
                  word.meaning.toLowerCase().contains(_wordsSearchQuery.toLowerCase())
                ).toList();
              }
              
              if (_selectedCategory.isNotEmpty) {
                filteredWords = filteredWords.where((word) => word.category == _selectedCategory).toList();
              }

              return _buildWordsView(filteredWords);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWordsView(List<Word> words) {
    switch (_viewMode) {
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
      padding: const EdgeInsets.all(12),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              word.text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(word.meaning),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(word.category).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                word.category,
                style: TextStyle(
                  color: _getCategoryColor(word.category),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => _showWordDetails(word),
          ),
        );
      },
    );
  }

  Widget _buildWordsGrid(List<Word> words, int columns) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: columns == 3 ? 0.9 : 0.8,
      ),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return _buildWordCard(word, columns);
      },
    );
  }

  Widget _buildWordCard(Word word, int columns) {
    final isSmall = columns == 4;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showWordDetails(word),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 6 : 8),
          child: Column(
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
                child: Text(
                  word.meaning,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isSmall ? 12 : 14,
                  ),
                  maxLines: isSmall ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }

  Widget _buildListsTab() {
    return StreamBuilder<List<WordList>>(
      stream: _firestoreService.getLists(),
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
                  onPressed: () => setState(() {}),
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
                  onPressed: _showCreateListDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create List'),
                ),
              ],
            ),
          );
        }

        // Filter lists
        List<WordList> filteredLists = snapshot.data!;
        if (_listsSearchQuery.isNotEmpty) {
          filteredLists = filteredLists.where((list) =>
            list.name.toLowerCase().contains(_listsSearchQuery.toLowerCase()) ||
            list.description.toLowerCase().contains(_listsSearchQuery.toLowerCase())
          ).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredLists.length,
          itemBuilder: (context, index) {
            final list = filteredLists[index];
            return _buildListCard(list);
          },
        );
      },
    );
  }

  Widget _buildListCard(WordList list) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openListDetails(list),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.library_books,
                  color: Theme.of(context).primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (list.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        list.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.book,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${list.wordCount} words',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(list.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    _deleteList(list);
                  } else if (value == 'edit') {
                    _editList(list);
                  }
                },
                itemBuilder: (context) => [
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Dialog methods implementation
  void _showSearchDialog() {
    final searchController = TextEditingController();
    final isWordsTab = _tabController.index == 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search ${isWordsTab ? "Words" : "Lists"}'),
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: isWordsTab ? 'Search words or meanings...' : 'Search lists...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (isWordsTab) {
                  _wordsSearchQuery = searchController.text;
                } else {
                  _listsSearchQuery = searchController.text;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showAddWordDialog() {
    final wordController = TextEditingController();
    String selectedCategory = 'Good';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Word'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wordController,
                decoration: const InputDecoration(
                  labelText: 'Word (English)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., apple, house, beautiful',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ['Very Good', 'Good', 'Bad'].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(_getCategoryIcon(category), color: _getCategoryColor(category)),
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setDialogState(() => selectedCategory = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (wordController.text.trim().isEmpty) return;
                
                setDialogState(() => isLoading = true);
                
                try {
                  await _firestoreService.addWord(
                    wordController.text.trim(),
                    category: selectedCategory,
                  );
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Word added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding word: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                
                setDialogState(() => isLoading = false);
              },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Word'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateListDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'List Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Travel Words, Business Terms',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Describe what this list is for...',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (nameController.text.trim().isEmpty) return;
                
                setDialogState(() => isLoading = true);
                
                try {
                  await _firestoreService.createList(
                    nameController.text.trim(),
                    description: descriptionController.text.trim(),
                  );
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('List created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating list: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                
                setDialogState(() => isLoading = false);
              },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create List'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWordDetails(Word word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(word.text),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meaning:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(word.meaning),
            if (word.exampleSentence.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Example:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(word.exampleSentence),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Category: ',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(word.category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    word.category,
                    style: TextStyle(
                      color: _getCategoryColor(word.category),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openListDetails(WordList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordListDetailsScreen(wordList: list),
      ),
    );
  }

  void _deleteList(WordList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "${list.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.deleteList(list.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('List deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting list: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editList(WordList list) {
    final nameController = TextEditingController(text: list.name);
    final descriptionController = TextEditingController(text: list.description);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'List Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (nameController.text.trim().isEmpty) return;
                
                setDialogState(() => isLoading = true);
                
                try {
                  await _firestoreService.updateList(
                    listId: list.id,
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                  );
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('List updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating list: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                
                setDialogState(() => isLoading = false);
              },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Very Good':
        return Icons.star;
      case 'Good':
        return Icons.check_circle;
      case 'Bad':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}

enum ViewMode { list, grid3, grid4 }
