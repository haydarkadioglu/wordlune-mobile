import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import '../models/story.dart';
import '../services/story_service.dart';
import '../services/translation_service.dart';
import '../services/language_preference_service.dart';

class StoryReaderScreen extends StatefulWidget {
  final Story story;

  const StoryReaderScreen({Key? key, required this.story}) : super(key: key);

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  final StoryService _storyService = StoryService();
  final ScrollController _scrollController = ScrollController();
  bool _isLiked = false;
  bool _isBookmarked = false;
  double _fontSize = 16.0;
  String _translationLanguage = 'Turkish';
  Map<String, String> _wordTranslations = {};

  @override
  void initState() {
    super.initState();
    // Hikaye görüntüleme sayısını artır
    _incrementViewCount();
    // Çeviri dilini yükle
    _loadTranslationLanguage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTranslationLanguage() async {
    final language = await LanguagePreferenceService.getTranslationLanguage();
    setState(() {
      _translationLanguage = language;
    });
  }

  Future<void> _incrementViewCount() async {
    try {
      print('Incrementing view count for story: ${widget.story.id}, language: ${widget.story.language}');
      await _storyService.incrementViewCount(widget.story.id, widget.story.language);
    } catch (e) {
      print('Failed to increment view count: $e');
    }
  }

  Future<void> _toggleLike() async {
    try {
      if (_isLiked) {
        await _storyService.decrementLikeCount(widget.story.id, widget.story.language);
      } else {
        await _storyService.incrementLikeCount(widget.story.id, widget.story.language);
      }
      setState(() {
        _isLiked = !_isLiked;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Reading Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Font Size Slider
            Row(
              children: [
                const Text('Font Size: '),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 24.0,
                    divisions: 6,
                    label: _fontSize.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _fontSize = value;
                      });
                    },
                  ),
                ),
                Text('${_fontSize.round()}'),
              ],
            ),
            const SizedBox(height: 20),
            // Translation Language Dropdown
            Row(
              children: [
                const Text('Translation Language: '),
                Expanded(
                  child: DropdownButton<String>(
                    value: _translationLanguage,
                    isExpanded: true,
                    items: LanguagePreferenceService.availableLanguages
                        .map((language) => DropdownMenuItem(
                              value: language,
                              child: Text(language),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _translationLanguage = value;
                        });
                        await LanguagePreferenceService.setTranslationLanguage(value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Translation language set to $value'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            // Info text
            Text(
              'Tap on any word in the story to translate it to $_translationLanguage',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _scrollToTop();
                  },
                  icon: const Icon(Icons.keyboard_arrow_up),
                  label: const Text('Top'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _scrollToBottom();
                  },
                  icon: const Icon(Icons.keyboard_arrow_down),
                  label: const Text('Bottom'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _translateWord(String word, Offset tapPosition) async {
    // Önceden çevrilmiş mi kontrol et
    if (_wordTranslations.containsKey(word.toLowerCase())) {
      _showTranslationTooltip(word, _wordTranslations[word.toLowerCase()]!, tapPosition);
      return;
    }

    // Loading indicator göster
    _showLoadingTooltip(word, tapPosition);

    try {
      final targetLanguageCode = LanguagePreferenceService.getTranslationCode(_translationLanguage);
      final sourceLanguageCode = LanguagePreferenceService.getTranslationCode(
        LanguagePreferenceService.getLanguageFromCode(widget.story.language)
      );
      
      final translation = await TranslationService.translate(
        text: word,
        targetLanguage: targetLanguageCode,
        sourceLanguage: sourceLanguageCode,
      );

      // Cache'e ekle
      _wordTranslations[word.toLowerCase()] = translation;

      // Loading tooltip'i kapat
      _hideTooltip();

      // Çeviri tooltip'ini göster
      _showTranslationTooltip(word, translation, tapPosition);
      
    } catch (e) {
      // Loading tooltip'i kapat
      _hideTooltip();
      
      // Hata tooltip'i göster
      _showErrorTooltip(word, e.toString(), tapPosition);
    }
  }

  OverlayEntry? _tooltipOverlay;

  void _showLoadingTooltip(String word, Offset position) {
    _hideTooltip();
    
    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 100,
        top: position.dy - 60,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Translating...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_tooltipOverlay!);
  }

  void _showTranslationTooltip(String originalWord, String translation, Offset position) {
    _hideTooltip();
    
    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 100,
        top: position.dy - 80,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _hideTooltip,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[600]!
                      : Colors.grey[300]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original word
                  Text(
                    originalWord,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Translation
                  Text(
                    translation,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Add to list button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _hideTooltip();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add to word list feature coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                size: 12,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_tooltipOverlay!);
    
    // 5 saniye sonra otomatik kapat
    Timer(const Duration(seconds: 5), _hideTooltip);
  }

  void _showErrorTooltip(String word, String error, Offset position) {
    _hideTooltip();
    
    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 100,
        top: position.dy - 60,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _hideTooltip,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Translation failed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_tooltipOverlay!);
    
    // 3 saniye sonra otomatik kapat
    Timer(const Duration(seconds: 3), _hideTooltip);
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  Widget _buildClickableText(String content) {
    final words = content.split(RegExp(r'(\s+|[.,!?;:()"' + r"'" + r'\[\]{}<>])'));
    final spans = <InlineSpan>[];
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      
      if (RegExp(r'^[a-zA-ZüğıöşÜĞIÖŞçÇ]+$').hasMatch(word) && word.length > 2) {
        // Clickable word
        spans.add(
          WidgetSpan(
            child: GestureDetector(
              onTapDown: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final globalPosition = renderBox.localToGlobal(details.localPosition);
                _translateWord(word, globalPosition);
              },
              child: Text(
                word,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: 1.6,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue[300]
                      : Colors.blue[700],
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue.withOpacity(0.4),
                  decorationStyle: TextDecorationStyle.dotted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      } else {
        // Non-clickable text (spaces, punctuation, etc.)
        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.6,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
            ),
          ),
        );
      }
    }
    
    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.justify,
    );
  }

  void _shareStory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.blue,
              foregroundColor: Colors.white,
              title: Text(
                widget.story.title,
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  onPressed: _showSettingsBottomSheet,
                  icon: const Icon(Icons.settings),
                ),
                IconButton(
                  onPressed: _shareStory,
                  icon: const Icon(Icons.share),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 100,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.grey[50],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.story.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white24,
                            radius: 16,
                            child: Text(
                              widget.story.authorName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'By ${widget.story.authorName}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Published ${_formatDate(widget.story.createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Story meta info bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.grey[50],
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey[300]!,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildLevelChip(widget.story.level),
                      const SizedBox(width: 8),
                      _buildCategoryChip(widget.story.category),
                      const Spacer(),
                      Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.story.viewCount + 1}', // +1 because we incremented it
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.story.likeCount}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  if (widget.story.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.story.tags
                          .map((tag) => Chip(
                                label: Text(tag),
                                backgroundColor: Colors.blue[50],
                                labelStyle: const TextStyle(fontSize: 12),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            // Story Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClickableText(widget.story.content),
                    const SizedBox(height: 40),
                    // Story End Marker
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '📖 End of Story',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // Extra space for bottom actions
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like button
        FloatingActionButton(
          heroTag: "like",
          onPressed: _toggleLike,
          backgroundColor: _isLiked ? Colors.red : Colors.grey[300],
          child: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.white : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
        // Bookmark button
        FloatingActionButton(
          heroTag: "bookmark",
          onPressed: () {
            setState(() {
              _isBookmarked = !_isBookmarked;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isBookmarked 
                    ? 'Story bookmarked!' 
                    : 'Bookmark removed!',
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          backgroundColor: _isBookmarked ? Colors.blue : Colors.grey[300],
          child: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: _isBookmarked ? Colors.white : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
        // Share button
        FloatingActionButton(
          heroTag: "share",
          onPressed: _shareStory,
          backgroundColor: Colors.grey[300],
          child: Icon(Icons.share, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLevelChip(String level) {
    Color chipColor;
    switch (level.toUpperCase()) {
      case 'A1':
        chipColor = Colors.green;
        break;
      case 'A2':
        chipColor = Colors.lightGreen;
        break;
      case 'B1':
        chipColor = Colors.orange;
        break;
      case 'B2':
        chipColor = Colors.deepOrange;
        break;
      case 'C1':
        chipColor = Colors.red;
        break;
      case 'C2':
        chipColor = Colors.purple;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(category),
            size: 12,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fiction':
        return Icons.auto_stories;
      case 'literature':
        return Icons.library_books;
      case 'non-fiction':
        return Icons.article;
      case 'news':
        return Icons.newspaper;
      case 'academic':
        return Icons.school;
      case 'science':
        return Icons.science;
      case 'technology':
        return Icons.computer;
      case 'business':
        return Icons.business;
      case 'history':
        return Icons.history_edu;
      case 'culture':
        return Icons.language;
      default:
        return Icons.book;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
