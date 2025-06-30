import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/word.dart';

class DashboardProgressContainer extends StatelessWidget {
  final FirestoreService firestoreService;

  const DashboardProgressContainer({
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
            'Your Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressStats(context),
        ],
      ),
    );
  }

  Widget _buildProgressStats(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return StreamBuilder<List<Word>>(
      stream: firestoreService.getWords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final words = snapshot.data!;
        final totalWords = words.length;
        final goodWords = words.where((w) => w.category == 'Good').length;
        final veryGoodWords = words.where((w) => w.category == 'Very Good').length;
        final badWords = words.where((w) => w.category == 'Bad').length;

        return Column(
          children: [
            Text(
              'Total $totalWords Words',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressItem(context, 'Very Good', veryGoodWords, totalWords, Colors.green),
            const SizedBox(height: 8),
            _buildProgressItem(context, 'Good', goodWords, totalWords, Colors.orange),
            const SizedBox(height: 8),
            _buildProgressItem(context, 'Need Practice', badWords, totalWords, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildProgressItem(BuildContext context, String label, int count, int total, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? color.withOpacity(0.9) : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: isDarkMode ? Colors.white10 : Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDarkMode ? color.withOpacity(0.8) : color,
          ),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
