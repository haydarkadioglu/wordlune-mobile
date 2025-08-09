import 'package:flutter/material.dart';
import '../../models/list_word.dart';
import '../../models/word_list.dart';
import '../../services/firestore_service.dart';
import 'list_word_card.dart';
import 'search_sort_bar.dart';

class WordListView extends StatelessWidget {
  final WordList wordList;
  final FirestoreService firestoreService;
  final String searchQuery;
  final SortOption currentSortOption;
  final Function(ListWord) onEditWord;
  final Function(ListWord) onDeleteWord;
  final VoidCallback onAddWord;

  const WordListView({
    super.key,
    required this.wordList,
    required this.firestoreService,
    required this.searchQuery,
    required this.currentSortOption,
    required this.onEditWord,
    required this.onDeleteWord,
    required this.onAddWord,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ListWord>>(
      stream: firestoreService.getWordsInList(wordList.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final allWords = snapshot.data ?? [];
        
        // Sort words
        List<ListWord> sortedWords = List.from(allWords);
        switch (currentSortOption) {
          case SortOption.alphabetical:
            sortedWords.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
            break;
          case SortOption.dateAdded:
            sortedWords.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
          case SortOption.dateAddedReverse:
            sortedWords.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            break;
        }
        
        // Filter by search
        final words = searchQuery.isEmpty
            ? sortedWords
            : sortedWords.where((word) =>
                word.word.toLowerCase().contains(searchQuery) ||
                word.meaning.toLowerCase().contains(searchQuery) ||
                word.exampleSentence.toLowerCase().contains(searchQuery)).toList();
        
        if (words.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  searchQuery.isNotEmpty ? Icons.search_off : Icons.note_alt_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isNotEmpty ? 'No words match your search' : 'No words in this list',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (searchQuery.isEmpty) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onAddWord,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Word'),
                  ),
                ],
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: words.length,
          itemBuilder: (context, index) {
            final word = words[index];
            return ListWordCard(
              word: word,
              onEdit: onEditWord,
              onDelete: onDeleteWord,
            );
          },
        );
      },
    );
  }
}
