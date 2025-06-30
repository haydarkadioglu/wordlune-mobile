import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'dashboard_app_bar.dart';
import 'dashboard_stats_cards.dart';
import 'dashboard_progress_container.dart';
import 'dashboard_quick_actions.dart';
import 'dashboard_recent_words.dart';
import 'dashboard_weekly_progress.dart';

class DashboardHome extends StatelessWidget {
  final FirestoreService firestoreService;
  final VoidCallback onAddWordTap;
  final VoidCallback onTranslateTap;

  const DashboardHome({
    super.key,
    required this.firestoreService,
    required this.onAddWordTap,
    required this.onTranslateTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh of the whole widget
      },
      child: CustomScrollView(
        slivers: [
          const DashboardAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                DashboardStatsCards(firestoreService: firestoreService),
                const SizedBox(height: 16),
                DashboardProgressContainer(firestoreService: firestoreService),
                const SizedBox(height: 16),
                DashboardQuickActions(
                  onAddWordTap: onAddWordTap,
                  onTranslateTap: onTranslateTap,
                ),
                const SizedBox(height: 16),
                DashboardRecentWords(firestoreService: firestoreService),
                const SizedBox(height: 16),
                DashboardWeeklyProgress(firestoreService: firestoreService),
                const SizedBox(height: 80), // Extra space for bottom navigation
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
