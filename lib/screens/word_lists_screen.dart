import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/word_list.dart';
import 'list_details_screen.dart';
import '../components/word_lists/empty_lists_state.dart';
import '../components/word_lists/word_list_card.dart';
import '../components/dialogs/create_list_dialog.dart';
import '../components/dialogs/search_lists_dialog.dart';
import '../components/dialogs/delete_list_dialog.dart';

class WordListsScreen extends StatefulWidget {
  const WordListsScreen({super.key});

  @override
  State<WordListsScreen> createState() => _WordListsScreenState();
}

class _WordListsScreenState extends State<WordListsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Word Lists'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateListDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<WordList>>(
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
                  Icon(Icons.error, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text('Error loading lists: ${snapshot.error}'),
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
            return EmptyListsState(onCreateList: _showCreateListDialog);
          }

          var lists = snapshot.data!;
          
          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            lists = lists.where((list) =>
              list.name.toLowerCase().contains(_searchQuery.toLowerCase())
            ).toList();
          }

          if (lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No lists match your search'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _searchQuery = ''),
                    child: const Text('Clear Search'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return WordListCard(
                list: list,
                onTap: () => _openListDetails(list),
                onDelete: () => _showDeleteListDialog(list),
              );
            },
          );
        },
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => SearchListsDialog(
        currentQuery: _searchQuery,
        onSearchChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateListDialog(
        onListCreated: (name) async {
          await _firestoreService.addList(name);
        },
      ),
    );
  }

  void _showDeleteListDialog(WordList list) {
    showDialog(
      context: context,
      builder: (context) => DeleteListDialog(
        list: list,
        onDelete: () async {
          await _firestoreService.deleteWordList(list.id);
        },
      ),
    );
  }
}
