import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
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
    // Load view mode synchronously first with default, then async load the saved preference
    _loadViewModeSync();
  }
  
  void _loadViewModeSync() {
    // Set default immediately
    _viewMode = ViewMode.grid3;
    
    // Then load from preferences asynchronously
    _loadViewModeAsync();
  }
  
  Future<void> _loadViewModeAsync() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Small delay to ensure UI is ready
      
      String? savedViewMode;
      
      // Try SharedPreferences first
      try {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        print('All SharedPreferences keys: $keys');
        savedViewMode = prefs.getString('words_view_mode');
        print('SharedPreferences view mode: $savedViewMode');
      } catch (e) {
        print('SharedPreferences failed: $e');
      }
      
      // If SharedPreferences failed or returned null, try file storage
      if (savedViewMode == null) {
        savedViewMode = await _loadViewModeFromFile();
        print('File storage view mode: $savedViewMode');
        
        // If we got a value from file, save it back to SharedPreferences
        if (savedViewMode != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('words_view_mode', savedViewMode);
            print('Restored SharedPreferences from file');
          } catch (e) {
            print('Failed to restore SharedPreferences: $e');
          }
        }
      }
      
      if (savedViewMode != null && mounted) {
        final newMode = _parseViewMode(savedViewMode);
        setState(() {
          _viewMode = newMode;
        });
        print('Successfully restored view mode: $savedViewMode -> $newMode');
      } else {
        print('No saved view mode found or widget not mounted');
      }
    } catch (e) {
      print('Error loading view mode: $e');
    }
  }

  Future<void> _saveViewMode(ViewMode mode) async {
    try {
      print('Attempting to save view mode: $mode');
      
      final modeString = _viewModeToString(mode);
      
      // Save to both SharedPreferences and file
      bool sharedPrefsSuccess = false;
      bool fileSuccess = false;
      
      // Try SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('words_view_mode');
        final success = await prefs.setString('words_view_mode', modeString);
        await prefs.commit();
        
        final verification = prefs.getString('words_view_mode');
        print('SharedPreferences - Success: $success, Verified: $verification');
        sharedPrefsSuccess = success && verification == modeString;
      } catch (e) {
        print('SharedPreferences save failed: $e');
      }
      
      // Try file storage
      try {
        await _saveViewModeToFile(mode);
        final verification = await _loadViewModeFromFile();
        print('File storage - Verified: $verification');
        fileSuccess = verification == modeString;
      } catch (e) {
        print('File storage save failed: $e');
      }
      
      print('Save results - SharedPrefs: $sharedPrefsSuccess, File: $fileSuccess');
      
    } catch (e) {
      print('Error saving view mode: $e');
    }
  }

  // Alternative file-based storage methods
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/view_mode.txt');
  }

  Future<void> _saveViewModeToFile(ViewMode mode) async {
    try {
      final file = await _localFile;
      final modeString = _viewModeToString(mode);
      await file.writeAsString(modeString);
      print('Saved view mode to file: $modeString');
    } catch (e) {
      print('Error saving view mode to file: $e');
    }
  }

  Future<String?> _loadViewModeFromFile() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        print('Loaded view mode from file: $contents');
        return contents;
      }
      return null;
    } catch (e) {
      print('Error loading view mode from file: $e');
      return null;
    }
  }

  // Safe ViewMode conversion with fallback
  ViewMode _parseViewMode(String? modeString) {
    if (modeString == null) return ViewMode.grid3;
    
    switch (modeString.toLowerCase().trim()) {
      case 'list':
        return ViewMode.list;
      case 'grid3':
        return ViewMode.grid3;
      case 'grid4':
        return ViewMode.grid4;
      default:
        print('Unknown view mode: $modeString, using default grid3');
        return ViewMode.grid3;
    }
  }
  
  String _viewModeToString(ViewMode mode) {
    switch (mode) {
      case ViewMode.list:
        return 'list';
      case ViewMode.grid3:
        return 'grid3';
      case ViewMode.grid4:
        return 'grid4';
    }
  }

  // Test function to check SharedPreferences
  Future<void> _testSharedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentValue = prefs.getString('words_view_mode');
      final allKeys = prefs.getKeys();
      final fileValue = await _loadViewModeFromFile();
      
      print('=== STORAGE TEST ===');
      print('All SharedPreferences keys: $allKeys');
      print('SharedPreferences value: $currentValue');
      print('File storage value: $fileValue');
      print('Current _viewMode: $_viewMode');
      print('ViewMode enum values: ${ViewMode.values}');
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Storage Test'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SharedPrefs: ${currentValue ?? "null"}'),
                Text('File Storage: ${fileValue ?? "null"}'),
                Text('Current: $_viewMode'),
                Text('All keys: ${allKeys.length}'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await prefs.clear();
                          Navigator.pop(context);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('SharedPreferences cleared!')),
                            );
                          }
                        },
                        child: const Text('Clear Prefs'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final file = await _localFile;
                          if (await file.exists()) {
                            await file.delete();
                          }
                          Navigator.pop(context);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('File storage cleared!')),
                            );
                          }
                        },
                        child: const Text('Clear File'),
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
    } catch (e) {
      print('Test error: $e');
    }
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
            onViewModeChanged: (mode) async {
              print('View mode changed to: $mode');
              setState(() => _viewMode = mode);
              await _saveViewMode(mode);
              
              // Test to show current state
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('View mode changed to: ${mode.toString().split('.').last}'),
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: 'Test',
                      onPressed: _testSharedPrefs,
                    ),
                  ),
                );
              }
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
