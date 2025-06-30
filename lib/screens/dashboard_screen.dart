import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../services/firestore_service.dart';
import '../services/version_check_service.dart';
import '../components/dashboard/dashboard_home.dart';
import '../components/dashboard/dashboard_quick_add_dialog.dart';
import 'words_lists_combined_screen.dart';
import 'translator_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Record login history when dashboard loads
    _firestoreService.recordLoginHistory();
    
    // Version kontrolü yap (async olarak)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }
  
  Future<void> _checkForUpdates() async {
    try {
      await VersionCheckService.checkForUpdates(context);
    } catch (e) {
      print('Version check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        physics: const BouncingScrollPhysics(),
        children: [
          DashboardHome(
            firestoreService: _firestoreService,
            onAddWordTap: _showQuickAddDialog,
            onTranslateTap: _navigateToTranslator,
          ),
          const TranslatorScreen(),
          const WordsListsCombinedScreen(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 65,
        items: [
          Icon(Icons.dashboard_rounded, size: 26, color: Colors.white),
          Icon(Icons.translate_rounded, size: 26, color: Colors.white),
          Icon(Icons.library_books, size: 26, color: Colors.white),
        ],
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF1E1E2E)
          : const Color(0xFF4FC3F7),
        buttonBackgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF4FC3F7)
          : const Color(0xFF0288D1),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOutCubic,
        animationDuration: const Duration(milliseconds: 350),
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        },
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: _showQuickAddDialog,
        backgroundColor: const Color(0xFF4FC3F7),
        elevation: 8,
        child: const Icon(Icons.flash_on, color: Colors.white, size: 28),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showQuickAddDialog() {
    showDialog(
      context: context,
      builder: (context) => DashboardQuickAddDialog(firestoreService: _firestoreService),
    );
  }

  void _navigateToTranslator() {
    setState(() => _currentIndex = 1);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }
}
