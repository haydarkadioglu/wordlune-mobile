import 'package:flutter/material.dart';
import '../../models/word_list.dart';
import '../../services/firestore_service.dart';

class ListInfoCard extends StatelessWidget {
  final WordList wordList;
  final FirestoreService firestoreService;

  const ListInfoCard({
    super.key,
    required this.wordList,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wordList.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Created on ${_formatDate(wordList.createdAt)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                StreamBuilder<int>(
                  stream: firestoreService.countWordsInList(wordList.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$count ${count == 1 ? 'word' : 'words'}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            if (wordList.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(wordList.description),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
