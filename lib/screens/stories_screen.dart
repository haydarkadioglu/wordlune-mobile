import 'package:flutter/material.dart';
import '../models/story.dart';
import '../services/story_service.dart';
import '../services/language_preference_service.dart';
import '../services/test_data_service.dart';
import 'story_reader_screen.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({Key? key}) : super(key: key);

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> with TickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  late TabController _tabController;
  String _selectedLanguage = 'turkish';
  String _selectedLevel = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLanguagePreference();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguagePreference() async {
    final language = await LanguagePreferenceService.getSelectedLanguage();
    final languageCode = LanguagePreferenceService.getLanguageCode(language);
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.blue,
              foregroundColor: Colors.white,
              title: const Text('Stories'),
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(icon: Icon(Icons.explore), text: 'Browse'),
                  Tab(icon: Icon(Icons.person), text: 'My Stories'),
                  Tab(icon: Icon(Icons.add), text: 'Create'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBrowseTab(),
            _buildMyStoriesTab(),
            _buildCreateTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedLevel,
                  items: ['All', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                      .map((level) => DropdownMenuItem(
                            value: level,
                            child: Text(level == 'All' ? 'All Levels' : level),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLevel = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement search
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search feature coming soon!')),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ],
          ),
        ),
        // Stories List
        Expanded(
          child: StreamBuilder<List<Story>>(
            stream: _selectedLevel == 'All'
                ? _storyService.getPublicStories(language: _selectedLanguage)
                : _storyService.getStoriesByLevel(
                    _selectedLevel,
                    language: _selectedLanguage,
                  ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Rebuild to retry
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final stories = snapshot.data ?? [];

              if (stories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_stories, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No stories found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Be the first to publish a story!',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Creating test stories...')),
                          );
                          await TestDataService.createTestStory();
                          await TestDataService.createTurkishTestStory();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Test stories created!')),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Create Test Stories'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return _buildStoryCard(story);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyStoriesTab() {
    return StreamBuilder<List<AuthorStory>>(
      stream: _storyService.getAuthorStories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Rebuild to retry
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final stories = snapshot.data ?? [];

        if (stories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.create, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No stories yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start writing your first story!',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(2); // Go to Create tab
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Story'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _fixAuthorStories,
                  icon: const Icon(Icons.build, color: Colors.white),
                  label: const Text('Fix My Stories', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            return _buildAuthorStoryCard(story);
          },
        );
      },
    );
  }

  Widget _buildCreateTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Create New Story',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share your stories and help others learn languages',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _showCreateStoryDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('Start Writing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Story creation form coming soon!',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(Story story) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showStoryDetail(story);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'By ${story.authorName}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildLevelChip(story.level),
                  const SizedBox(width: 8),
                  _buildCategoryChip(story.category),
                  const Spacer(),
                  Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${story.viewCount}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${story.likeCount}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              if (story.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: story.tags
                      .take(3)
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
      ),
    );
  }

  Widget _buildAuthorStoryCard(AuthorStory story) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showStoryOptions(story);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      story.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleStoryAction(action, story),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: story.isPublished ? 'unpublish' : 'publish',
                        child: Row(
                          children: [
                            Icon(story.isPublished ? Icons.visibility_off : Icons.visibility),
                            const SizedBox(width: 8),
                            Text(story.isPublished ? 'Unpublish' : 'Publish'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    story.isPublished ? Icons.public : Icons.drafts,
                    size: 16,
                    color: story.isPublished ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    story.isPublished ? 'Published' : 'Draft',
                    style: TextStyle(
                      color: story.isPublished ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Language: ${story.language}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${story.createdAt.day}/${story.createdAt.month}/${story.createdAt.year}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
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

  void _showStoryDetail(Story story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryReaderScreen(story: story),
      ),
    );
  }

  void _showStoryOptions(AuthorStory story) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Managing "${story.title}"...')),
    );
  }

  void _handleStoryAction(String action, AuthorStory story) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action action for "${story.title}" - Coming soon!')),
    );
  }

  void _showCreateStoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Story'),
        content: const Text('Story creation form will be implemented soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _fixAuthorStories() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fixing author stories data...')),
      );

      await _storyService.fixAuthorStoriesData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Author stories fixed! Your stories should now appear.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fixing stories: $e')),
      );
    }
  }
}
