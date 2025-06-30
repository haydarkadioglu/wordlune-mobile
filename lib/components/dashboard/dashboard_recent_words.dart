import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/word.dart';

class DashboardRecentWords extends StatelessWidget {
  final FirestoreService firestoreService;

  const DashboardRecentWords({
    super.key,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A3F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black12 : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Words',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Word>>(
            stream: firestoreService.getRecentWords(limit: 5),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No words yet. Start by adding some!',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                separatorBuilder: (context, index) => Divider(
                  color: isDarkMode ? Colors.white12 : Colors.black12,
                ),
                itemBuilder: (context, index) {
                  final word = snapshot.data![index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      word.text,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      word.meaning,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    trailing: Icon(
                      _getCategoryIcon(word.category),
                      color: _getCategoryColor(word.category),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
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
        return Icons.help_outline;
    }
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
}
