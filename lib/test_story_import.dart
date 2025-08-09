import '../models/story.dart';

void testStoryImport() {
  // Test if Story and AuthorStory classes can be accessed
  var story = Story(
    id: 'test',
    title: 'Test Story',
    content: 'Test content',
    authorId: 'author1',
    authorName: 'Test Author',
    isPublished: true,
    language: 'en',
    difficulty: 'Beginner',
    tags: ['test'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  var authorStory = AuthorStory(
    storyId: 'test',
    language: 'en',
    title: 'Test Story',
    isPublished: true,
    createdAt: DateTime.now(),
  );
  
  print('Story import test successful');
}
