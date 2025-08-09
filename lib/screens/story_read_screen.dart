import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story.dart';
import '../services/story_service.dart';
import '../providers/language_provider.dart';
import '../services/language_preference_service.dart';

class StoryReadScreen extends StatefulWidget {
  final String storyId;
  final String language;

  const StoryReadScreen({
    Key? key,
    required this.storyId,
    required this.language,
  }) : super(key: key);

  @override
  State<StoryReadScreen> createState() => _StoryReadScreenState();
}

class _StoryReadScreenState extends State<StoryReadScreen> {
  final StoryService _storyService = StoryService();
  Story? story;
  bool isLoading = true;
  String? error;
  
  // Translation overlay
  OverlayEntry? _overlayEntry;
  String? _selectedWord;
  String? _translation;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  @override
  void dispose() {
    _removeTranslationOverlay();
    super.dispose();
  }

  Future<void> _loadStory() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Görüntüleme sayısını artır
      await _storyService.incrementViewCount(widget.storyId, widget.language);

      // Hikayeyi getir
      final fetchedStory = await _storyService.getStoryById(widget.storyId, widget.language);
      
      if (fetchedStory != null) {
        setState(() {
          story = fetchedStory;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Story not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error loading story: $e';
        isLoading = false;
      });
    }
  }

  void _removeTranslationOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _selectedWord = null;
      _translation = null;
      _isTranslating = false;
    });
  }

  Future<void> _translateWord(String word, Offset position) async {
    if (_selectedWord == word) {
      _removeTranslationOverlay();
      return;
    }

    _removeTranslationOverlay();

    setState(() {
      _selectedWord = word;
      _isTranslating = true;
    });

    try {
      // Kullanıcının hedef dilini al
      final selectedLanguage = context.read<LanguageProvider>().selectedLanguage;
      final targetLanguageCode = LanguagePreferenceService.getLanguageCode(selectedLanguage);
      
      // Basit çeviri simülasyonu - gerçek uygulamada translation API kullanılacak
      final translation = await _getTranslation(word, widget.language, targetLanguageCode);
      
      setState(() {
        _translation = translation;
        _isTranslating = false;
      });

      _showTranslationOverlay(position);
    } catch (e) {
      setState(() {
        _isTranslating = false;
        _translation = 'Translation failed';
      });
      _showTranslationOverlay(position);
    }
  }

  // Basit çeviri mock - gerçek uygulamada Google Translate API kullanılacak
  Future<String> _getTranslation(String word, String fromLanguage, String toLanguage) async {
    await Future.delayed(const Duration(milliseconds: 500)); // API çağrısı simülasyonu
    
    // Mock çeviri verileri
    final mockTranslations = {
      'hello': {'tr': 'merhaba', 'es': 'hola', 'fr': 'bonjour'},
      'world': {'tr': 'dünya', 'es': 'mundo', 'fr': 'monde'},
      'story': {'tr': 'hikaye', 'es': 'historia', 'fr': 'histoire'},
      'book': {'tr': 'kitap', 'es': 'libro', 'fr': 'livre'},
      'adventure': {'tr': 'macera', 'es': 'aventura', 'fr': 'aventure'},
      'love': {'tr': 'aşk', 'es': 'amor', 'fr': 'amour'},
      'journey': {'tr': 'yolculuk', 'es': 'viaje', 'fr': 'voyage'},
      'magic': {'tr': 'sihir', 'es': 'magia', 'fr': 'magie'},
      'forest': {'tr': 'orman', 'es': 'bosque', 'fr': 'forêt'},
      'castle': {'tr': 'kale', 'es': 'castillo', 'fr': 'château'},
    };

    final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
    
    if (mockTranslations.containsKey(cleanWord) && 
        mockTranslations[cleanWord]!.containsKey(toLanguage)) {
      return mockTranslations[cleanWord]![toLanguage]!;
    }
    
    return '$word → [Translation needed]';
  }

  void _showTranslationOverlay(Offset position) {
    if (_translation == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 100,
        top: position.dy - 60,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedWord ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _translation ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // 3 saniye sonra otomatik kapat
    Future.delayed(const Duration(seconds: 3), () {
      _removeTranslationOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(story?.title ?? 'Loading...'),
        actions: [
          if (story != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Hikayeyi paylaş
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality will be implemented')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {
                // Hikayeyi kaydet
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark functionality will be implemented')),
                );
              },
            ),
          ],
        ],
      ),
      body: GestureDetector(
        onTap: _removeTranslationOverlay,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (story == null) {
      return const Center(
        child: Text('Story not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hikaye başlığı
          Text(
            story!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Hikaye bilgileri
          Row(
            children: [
              _buildInfoChip(Icons.person, story!.authorName),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.signal_cellular_alt, story!.difficulty),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.visibility, '${story!.viewCount} views'),
            ],
          ),
          const SizedBox(height: 8),

          // Tags
          if (story!.tags.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              children: story!.tags.map((tag) => Chip(
                label: Text(
                  tag,
                  style: const TextStyle(fontSize: 10),
                ),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Çeviri ipucu
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.translate, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap any word to see its translation',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hikaye içeriği - tıklanabilir kelimeler
          _buildSelectableStoryContent(),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableStoryContent() {
    // Hikaye içeriğini kelimelere böl
    final words = story!.content.split(RegExp(r'(\s+)'));
    
    return RichText(
      text: TextSpan(
        children: words.map((part) {
          // Boşluk karakterleri için
          if (RegExp(r'^\s+$').hasMatch(part)) {
            return TextSpan(
              text: part,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            );
          }
          
          // Kelimeler için
          return WidgetSpan(
            child: GestureDetector(
              onTapDown: (details) {
                final cleanWord = part.replaceAll(RegExp(r'[^\w]'), '');
                if (cleanWord.length > 2) { // Sadece 2 karakterden uzun kelimeleri çevir
                  _translateWord(cleanWord, details.globalPosition);
                }
              },
              child: Container(
                decoration: _selectedWord == part.replaceAll(RegExp(r'[^\w]'), '')
                    ? BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                padding: _selectedWord == part.replaceAll(RegExp(r'[^\w]'), '')
                    ? const EdgeInsets.symmetric(horizontal: 2, vertical: 1)
                    : null,
                child: Text(
                  part,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: _selectedWord == part.replaceAll(RegExp(r'[^\w]'), '')
                        ? Colors.blue[800]
                        : Colors.black87,
                    fontWeight: _selectedWord == part.replaceAll(RegExp(r'[^\w]'), '')
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
