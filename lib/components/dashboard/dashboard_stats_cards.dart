import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/word.dart';

class DashboardStatsCards extends StatelessWidget {
  final FirestoreService firestoreService;

  const DashboardStatsCards({
    super.key,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Word>>(
      stream: firestoreService.getWords(),
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
                  onPressed: () {
                    // Trigger rebuild by recreating the stream
                  },
                  child: Text('Retry'),
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
                SizedBox(height: 16),
                Text(
                  'No words found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text(
                  'Add your first word to get started!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add_word'),
                  icon: Icon(Icons.add),
                  label: Text('Add Word'),
                ),
              ],
            ),
          );
        }

        final words = snapshot.data!;
        final veryGoodCount = words.where((w) => w.category == 'Very Good').length;
        final todayCount = words.where((w) => 
          w.dateAdded.day == DateTime.now().day &&
          w.dateAdded.month == DateTime.now().month &&
          w.dateAdded.year == DateTime.now().year
        ).length;

        return Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Total Words', words.length.toString(), Icons.book, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, 'Today', todayCount.toString(), Icons.today, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, 'Very Good', veryGoodCount.toString(), Icons.star, Colors.amber)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              count,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
