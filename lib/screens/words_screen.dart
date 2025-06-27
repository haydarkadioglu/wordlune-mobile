import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../models/word.dart';

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
                        Text('Loading words...'),
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
                  return _buildEmptyState();
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
                  return _buildEmptyState();
                }

                // Sort by date added (newest first)
                words.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

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
                    return _buildWordCard(word);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No Words Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start building your vocabulary\nby adding your first word!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddWordDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Word'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(Word word) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showWordDetails(word),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon and word
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(word.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(word.category),
                      color: _getCategoryColor(word.category),
                      size: 16,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (['Very Good', 'Good', 'Bad'].contains(value)) {
                        await _firestoreService.updateWordCategory(word.id, value);
                      } else if (value == 'delete') {
                        _showDeleteDialog(word);
                      }
                    },
                    itemBuilder: (context) => [
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
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Word text
              Text(
                word.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Meaning
              Text(
                word.meaning,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              
              // Date
              Text(
                '${word.dateAdded.day}/${word.dateAdded.month}/${word.dateAdded.year}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(word.meaning),
            
            if (word.ipa.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Pronunciation:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(word.ipa),
            ],
            
            if (word.example.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Example:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                word.example,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getCategoryIcon(word.category),
                  color: _getCategoryColor(word.category),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  word.category,
                  style: TextStyle(
                    color: _getCategoryColor(word.category),
                    fontWeight: FontWeight.w500,
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Words'),
        content: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Enter word or meaning...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
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
          await _firestoreService.addWordWithDetails(
            word: word,
            translation: meaning,
            ipa: ipa,
            example: example,
            category: category,
            language: language, // Pass the selected language
          );
        },
      ),
    );
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
                    SnackBar(
                      content: Text('Word "${word.text}" deleted!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting word: $e'),
                      backgroundColor: Colors.red,
                    ),
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Very Good':
        return Icons.star;
      case 'Good':
        return Icons.thumb_up;
      case 'Bad':
        return Icons.thumb_down;
      default:
        return Icons.help;
    }
  }
}

// Add Word Dialog
class AddWordDialog extends StatefulWidget {
  final Function(String word, String meaning, String ipa, String example, String category, String language) onWordAdded;

  const AddWordDialog({
    super.key,
    required this.onWordAdded,
  });

  @override
  State<AddWordDialog> createState() => _AddWordDialogState();
}

class _AddWordDialogState extends State<AddWordDialog> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _ipaController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  
  String _selectedCategory = 'Good';
  String _selectedLanguage = 'Turkish'; // Default language
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Word'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0), // Reduced bottom padding
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Word input
            TextField(
              controller: _wordController,
              decoration: const InputDecoration(
                labelText: 'Word *',
                border: OutlineInputBorder(),
                hintText: 'e.g., meeting',
                isDense: true, // Make the field more compact
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 12), // Reduced spacing
            
            // Meaning with AI button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _meaningController,
                    decoration: const InputDecoration(
                      labelText: 'Meaning *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., toplantı',
                      isDense: true, // Make the field more compact
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 6), // Reduced spacing
                SizedBox(
                  height: 48, // Reduced height
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _translateWord,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 14, // Smaller indicator
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.translate, size: 16), // Smaller icon
                    label: const Text('Çevir', style: TextStyle(fontSize: 12)), // Smaller text
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 6), // Reduced padding
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Reduced spacing
            
            // Language selection
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
                isDense: true, // Make the field more compact
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'Turkish', child: Text('Turkish')),
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'German', child: Text('German')),
                DropdownMenuItem(value: 'French', child: Text('French')),
                DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12), // Reduced spacing
            
            // IPA input
            TextField(
              controller: _ipaController,
              decoration: const InputDecoration(
                labelText: 'Pronunciation (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., /ˈmiːtɪŋ/',
                isDense: true, // Make the field more compact
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
            const SizedBox(height: 12), // Reduced spacing
            
            // Example with AI button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _exampleController,
                    decoration: const InputDecoration(
                      labelText: 'Example (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., We have a meeting at 3 PM',
                      isDense: true, // Make the field more compact
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 6), // Reduced spacing
                Column(
                  children: [
                    SizedBox(
                      height: 36, // Reduced height
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generateExample,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 12, // Smaller indicator
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome, size: 14), // Smaller icon
                        label: const Text('AI', style: TextStyle(fontSize: 11)), // Smaller text
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 6), // Reduced padding
                        ),
                      ),
                    ),
                    const SizedBox(height: 6), // Reduced spacing
                    SizedBox(
                      height: 36, // Reduced height
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _getFullDetails,
                        child: _isLoading 
                            ? const SizedBox(
                                width: 12, // Smaller indicator
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Full', style: TextStyle(fontSize: 11)), // Smaller text
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 6), // Reduced padding
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12), // Reduced spacing
            
            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                isDense: true, // Make the field more compact
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'Very Good', child: Text('Very Good')),
                DropdownMenuItem(value: 'Good', child: Text('Good')),
                DropdownMenuItem(value: 'Needs Review', child: Text('Needs Review')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () {
            if (_wordController.text.trim().isEmpty || _meaningController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Word and meaning are required')),
              );
              return;
            }
            
            widget.onWordAdded(
              _wordController.text.trim(), 
              _meaningController.text.trim(),
              _ipaController.text.trim(), 
              _exampleController.text.trim(), 
              _selectedCategory,
              _selectedLanguage, // Add the language parameter
            );
            
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
  
  Future<void> _translateWord() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a word first')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final translation = await _geminiService.translateWord(word);
      setState(() {
        _meaningController.text = translation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation error: $e')),
        );
      }
    }
  }
  
  Future<void> _generateExample() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a word first')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final example = await _geminiService.generateExample(word, _meaningController.text.trim());
      setState(() {
        _exampleController.text = example;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Example generation error: $e')),
        );
      }
    }
  }
  
  Future<void> _getFullDetails() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a word first')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final details = await _geminiService.getWordDetails(word);
      setState(() {
        if (details['meaning'] != null && details['meaning']!.isNotEmpty) {
          _meaningController.text = details['meaning']!;
        }
        if (details['example'] != null && details['example']!.isNotEmpty) {
          _exampleController.text = details['example']!;
        }
        if (details['ipa'] != null && details['ipa']!.isNotEmpty) {
          _ipaController.text = details['ipa']!;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching word details: $e')),
        );
      }
    }
  }
}
