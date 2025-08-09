import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story.dart';
import '../services/story_service.dart';
import '../providers/language_provider.dart';
import '../services/language_preference_service.dart';

class StoryCreateScreen extends StatefulWidget {
  final String? storyId; // Edit mode için

  const StoryCreateScreen({Key? key, this.storyId}) : super(key: key);

  @override
  State<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

class _StoryCreateScreenState extends State<StoryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final StoryService _storyService = StoryService();
  
  String _selectedDifficulty = 'Beginner';
  List<String> _selectedTags = [];
  bool _isLoading = false;
  bool _isDraft = true;

  @override
  void initState() {
    super.initState();
    if (widget.storyId != null) {
      _loadStoryForEditing();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadStoryForEditing() async {
    // Edit mode için story bilgilerini yükle
    // Bu implementasyon için şimdilik boş bırakıyoruz
    // Gerçek uygulamada author stories'ten detay çekilecek
  }

  bool get _isEditMode => widget.storyId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Story' : 'Create Story'),
        actions: [
          if (!_isLoading) ...[
            // Save as Draft
            TextButton(
              onPressed: _saveAsDraft,
              child: const Text('Save Draft'),
            ),
            // Publish
            TextButton(
              onPressed: _publishStory,
              child: Text(
                _isEditMode ? 'Update' : 'Publish',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language info
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.language, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Writing in: ${languageProvider.selectedLanguage}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Story Title',
                hintText: 'Enter an engaging title for your story',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Difficulty
            _buildDifficultySelector(),
            const SizedBox(height: 16),

            // Tags
            _buildTagSelector(),
            const SizedBox(height: 16),

            // Content
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Story Content',
                hintText: 'Write your story here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
              minLines: 10,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter story content';
                }
                if (value.trim().length < 50) {
                  return 'Story must be at least 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Writing tips
            _buildWritingTips(),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _saveAsDraft,
                    child: const Text('Save as Draft'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _publishStory,
                    child: Text(_isEditMode ? 'Update & Publish' : 'Publish Story'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Difficulty Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: StoryService.difficultyLevels.map((level) {
            final isSelected = _selectedDifficulty == level;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedDifficulty = level),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      level,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue[700] : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getDifficultyDescription(_selectedDifficulty),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getDifficultyDescription(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return 'Simple vocabulary and short sentences. Perfect for language learners.';
      case 'Intermediate':
        return 'Moderate vocabulary with some complex sentences. Good for improving language skills.';
      case 'Advanced':
        return 'Rich vocabulary and complex sentence structures. Challenging for advanced learners.';
      default:
        return '';
    }
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags (Select up to 5)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: StoryService.popularTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected && _selectedTags.length < 5) {
                    _selectedTags.add(tag);
                  } else if (!selected) {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: Colors.blue[100],
              checkmarkColor: Colors.blue[700],
            );
          }).toList(),
        ),
        if (_selectedTags.length >= 5) ...[
          const SizedBox(height: 8),
          Text(
            'Maximum 5 tags selected',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[700],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWritingTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.green[600]),
              const SizedBox(width: 8),
              Text(
                'Writing Tips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Use simple, clear language appropriate for your chosen difficulty level\n'
            '• Include engaging dialogue and descriptive scenes\n'
            '• Break text into paragraphs for better readability\n'
            '• Consider your target audience\'s language learning goals\n'
            '• Add cultural context to make the story more interesting',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAsDraft() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final storyId = await _storyService.createStory(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        difficulty: _selectedDifficulty,
        tags: _selectedTags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story saved as draft'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving draft: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _publishStory() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one tag'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String storyId;

      if (_isEditMode) {
        storyId = widget.storyId!;
        await _storyService.updateStory(
          storyId: storyId,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          difficulty: _selectedDifficulty,
          tags: _selectedTags,
        );
      } else {
        storyId = await _storyService.createStory(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          difficulty: _selectedDifficulty,
          tags: _selectedTags,
        );
      }

      // Publish the story
      await _storyService.publishStory(
        storyId: storyId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        difficulty: _selectedDifficulty,
        tags: _selectedTags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Story updated and published!' : 'Story published successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing story: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
