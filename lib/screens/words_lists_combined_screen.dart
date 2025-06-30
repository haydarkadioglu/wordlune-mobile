import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../models/word.dart';
import '../models/word_list.dart';
import 'list_details_screen.dart';
import '../components/words_lists/combined_screen_header.dart';
import '../components/words_lists/words_tab.dart';
import '../components/words_lists/lists_tab.dart';
import '../components/dialogs/add_word_dialog.dart';
import '../components/dialogs/create_list_dialog.dart';
import '../components/dialogs/word_details_dialog.dart';
import '../enums/view_mode.dart';

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
    _loadViewMode();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedViewMode = prefs.getString('words_view_mode') ?? 'grid3';
    
    setState(() {
      switch (savedViewMode) {
        case 'list':
          _viewMode = ViewMode.list;
          break;
        case 'grid3':
          _viewMode = ViewMode.grid3;
          break;
        case 'grid4':
          _viewMode = ViewMode.grid4;
          break;
        default:
          _viewMode = ViewMode.grid3;
      }
    });
  }

  Future<void> _saveViewMode(ViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    switch (mode) {
      case ViewMode.list:
        modeString = 'list';
        break;
      case ViewMode.grid3:
        modeString = 'grid3';
        break;
      case ViewMode.grid4:
        modeString = 'grid4';
        break;
    }
    await prefs.setString('words_view_mode', modeString);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom header
          CombinedScreenHeader(
            tabController: _tabController,
            viewMode: _viewMode,
            selectedCategory: _selectedCategory,
            onSearchPressed: _showSearchDialog,
            onAddPressed: _tabController.index == 0 ? _showAddWordDialog : _showCreateListDialog,
            onViewModeChanged: (mode) {
              setState(() => _viewMode = mode);
              _saveViewMode(mode);
            },
            onCategoryChanged: (category) => setState(() => _selectedCategory = category),
          ),
          
          // Tab bar with custom pill design
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[800] 
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(22.5),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  borderRadius: BorderRadius.circular(19),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(3),
                labelColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black87
                    : Colors.white,
                unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.book, size: 18),
                    text: 'Words',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                  Tab(
                    icon: Icon(Icons.folder, size: 18),
                    text: 'Lists',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                ],
              ),
            ),
          ),
          
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                WordsTab(
                  searchQuery: _wordsSearchQuery,
                  selectedCategory: _selectedCategory,
                  viewMode: _viewMode,
                  onAddWordPressed: _showAddWordDialog,
                  onWordTap: _showWordDetails,
                  onCategoryCleared: () => setState(() => _selectedCategory = ''),
                ),
                ListsTab(
                  searchQuery: _listsSearchQuery,
                  onCreateListPressed: _showCreateListDialog,
                  onListTap: _openListDetails,
                  onListMenuSelected: (list, value) {
                    if (value == 'delete') {
                      _deleteList(list);
                    } else if (value == 'edit') {
                      _editList(list);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dialog and action methods
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tabController.index == 0 ? 'Search Words' : 'Search Lists'),
        content: TextField(
          onChanged: (value) {
            setState(() {
              if (_tabController.index == 0) {
                _wordsSearchQuery = value;
              } else {
                _listsSearchQuery = value;
              }
            });
          },
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
          ),
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

  void _showAddWordDialog() {
    showDialog(
      context: context,
      builder: (context) => AddWordDialog(
        onWordAdded: (word, meaning, ipa, example, category, language) async {
          try {
            await _firestoreService.addWordWithDetails(
              word: word,
              translation: meaning,
              ipa: ipa,
              example: example,
              category: category,
              language: language,
            );
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Word "$word" added successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding word: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateListDialog(
        onListCreated: (name) async {
          try {
            await _firestoreService.createList(name, description: ''); // Empty description
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('List "$name" created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error creating list: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showWordDetails(Word word) {
    showDialog(
      context: context,
      builder: (context) => WordDetailsDialog(word: word),
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
        content: Text('Are you sure you want to delete "${list.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.deleteList(list.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('List "${list.name}" deleted!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting list: $e'),
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

  void _editList(WordList list) {
    // TODO: Implement edit list dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit list: ${list.name}')),
    );
  }
}
