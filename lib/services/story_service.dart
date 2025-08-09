import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/story.dart';
import 'language_preference_service.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  String get _authorName => FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous';

  // **PUBLIC STORIES COLLECTION**
  
  // Public hikayeler koleksiyonu - language bazlı
  CollectionReference _getPublicStoriesCollection(String language) {
    return _firestore
        .collection('stories')
        .doc(language)
        .collection('stories');
  }

  // Tüm public hikayeleri getir (dil bazlı)
  Stream<List<Story>> getPublicStories({String? language}) {
    final selectedLanguage = language ?? 'english'; // Default to english
    
    return _getPublicStoriesCollection(selectedLanguage)
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Story.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Level'a göre hikayeler (CEFR seviyeleri için)
  Stream<List<Story>> getStoriesByLevel(String level, {String? language}) {
    final selectedLanguage = language ?? 'english';
    
    return _getPublicStoriesCollection(selectedLanguage)
        .where('isPublished', isEqualTo: true)
        .where('level', isEqualTo: level)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Story.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Difficulty'ye göre hikayeler (backward compatibility için)
  Stream<List<Story>> getStoriesByDifficulty(String difficulty, {String? language}) {
    final selectedLanguage = language ?? 'english';
    
    return _getPublicStoriesCollection(selectedLanguage)
        .where('isPublished', isEqualTo: true)
        .where('difficulty', isEqualTo: difficulty)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Story.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Tag'e göre hikayeler
  Stream<List<Story>> getStoriesByTag(String tag, {String? language}) {
    final selectedLanguage = language ?? 'english';
    
    return _getPublicStoriesCollection(selectedLanguage)
        .where('isPublished', isEqualTo: true)
        .where('tags', arrayContains: tag)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Story.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Hikaye detayını getir
  Future<Story?> getStoryById(String storyId, String language) async {
    try {
      final doc = await _getPublicStoriesCollection(language).doc(storyId).get();
      if (doc.exists) {
        return Story.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting story: $e');
      return null;
    }
  }

  // Hikaye görüntüleme sayısını artır
  Future<void> incrementViewCount(String storyId, [String? language]) async {
    try {
      print('incrementViewCount called with storyId: "$storyId", language: "$language"');
      
      if (storyId.isEmpty) {
        print('Error: storyId is empty');
        return;
      }
      
      if (language != null && language.isNotEmpty) {
        // Belirli bir dilde ara
        print('Updating view count in language: $language');
        await _getPublicStoriesCollection(language).doc(storyId).update({
          'viewCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Tüm dillerde ara
        print('Searching in all languages for story: $storyId');
        final languages = ['english', 'turkish', 'spanish', 'french', 'german'];
        
        for (final lang in languages) {
          final storyRef = _getPublicStoriesCollection(lang).doc(storyId);
          final storyDoc = await storyRef.get();
          
          if (storyDoc.exists) {
            print('Found story in language: $lang, updating view count');
            await storyRef.update({
              'viewCount': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            break;
          }
        }
      }
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  // **AUTHOR STORIES COLLECTION**
  
  // Author hikayeleri koleksiyonu
  CollectionReference get _getAuthorStoriesCollection {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');
    
    return _firestore
        .collection('stories_by_author')
        .doc(userId)
        .collection('stories');
  }

  // Yazarın tüm hikayelerini getir
  Stream<List<AuthorStory>> getAuthorStories() {
    return _getAuthorStoriesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AuthorStory.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // **STORY CREATION & MANAGEMENT**
  
  // Yeni hikaye oluştur (taslak olarak)
  Future<String> createStory({
    required String title,
    required String content,
    required String difficulty,
    required List<String> tags,
    String? language,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    final selectedLanguage = language ?? await LanguagePreferenceService.getSelectedLanguage();
    final languageCode = LanguagePreferenceService.getLanguageCode(selectedLanguage);

    final now = DateTime.now();
    
    // 1. Author stories collection'a ekle (management için)
    final authorStoryRef = await _getAuthorStoriesCollection.add({
      'language': languageCode,
      'title': title,
      'isPublished': false,
      'createdAt': Timestamp.fromDate(now),
    });

    final storyId = authorStoryRef.id;

    // 2. AuthorStory'yi güncelle - storyId'yi ekle
    await authorStoryRef.update({'storyId': storyId});

    print('📝 Story created as draft: $storyId');
    print('   Title: $title');
    print('   Language: $languageCode');
    
    return storyId;
  }

  // Hikayeyi güncelle
  Future<void> updateStory({
    required String storyId,
    String? title,
    String? content,
    String? difficulty,
    List<String>? tags,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (title != null) updateData['title'] = title;
    if (content != null) updateData['content'] = content;
    if (difficulty != null) updateData['difficulty'] = difficulty;
    if (tags != null) updateData['tags'] = tags;

    // Author stories'i güncelle
    await _getAuthorStoriesCollection.doc(storyId).update({
      if (title != null) 'title': title,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    print('✏️ Story updated: $storyId');
  }

  // Hikayeyi yayınla (taslaktan public'e)
  Future<void> publishStory({
    required String storyId,
    required String title,
    required String content,
    required String difficulty,
    required List<String> tags,
    String? language,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    final selectedLanguage = language ?? await LanguagePreferenceService.getSelectedLanguage();
    final languageCode = LanguagePreferenceService.getLanguageCode(selectedLanguage);

    final now = DateTime.now();

    // 1. Public stories collection'a ekle
    final story = Story(
      id: storyId,
      title: title,
      content: content,
      authorId: userId,
      authorName: _authorName,
      isPublished: true,
      language: languageCode,
      level: difficulty, // CEFR level (A1, A2, B1, B2, C1, C2)
      category: 'General', // Default category
      tags: tags,
      createdAt: now,
      updatedAt: now,
      viewCount: 0,
      likeCount: 0,
    );

    await _getPublicStoriesCollection(languageCode).doc(storyId).set(story.toFirestore());

    // 2. Author stories'de published olarak işaretle
    await _getAuthorStoriesCollection.doc(storyId).update({
      'isPublished': true,
      'updatedAt': Timestamp.fromDate(now),
    });

    print('🚀 Story published: $storyId');
    print('   Language: $languageCode');
    print('   Public collection: stories/$languageCode/stories/$storyId');
  }

  // Hikayeyi yayından kaldır
  Future<void> unpublishStory(String storyId, String language) async {
    // 1. Public stories'ten kaldır
    await _getPublicStoriesCollection(language).doc(storyId).delete();

    // 2. Author stories'de unpublished olarak işaretle
    await _getAuthorStoriesCollection.doc(storyId).update({
      'isPublished': false,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    print('📥 Story unpublished: $storyId');
  }

  // Hikayeyi tamamen sil
  Future<void> deleteStory(String storyId, String language) async {
    // 1. Author stories'ten sil
    await _getAuthorStoriesCollection.doc(storyId).delete();

    // 2. Eğer published ise public stories'ten de sil
    try {
      await _getPublicStoriesCollection(language).doc(storyId).delete();
    } catch (e) {
      // Hikaye published değilse hata verir, normal
      print('Story was not published: $e');
    }

    print('🗑️ Story deleted: $storyId');
  }

  // **UTILITY METHODS**
  
  // Kullanıcının hikaye yazıp yazamayacağını kontrol et
  bool get canCreateStory => _userId != null;

  // Like count artır  
  Future<void> incrementLikeCount(String storyId, [String? language]) async {
    if (_userId == null) return;
    
    try {
      if (language != null) {
        // Belirli bir dilde ara
        await _getPublicStoriesCollection(language).doc(storyId).update({
          'likeCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Tüm dillerde ara
        final languages = ['english', 'turkish', 'spanish', 'french', 'german'];
        
        for (final lang in languages) {
          final storyRef = _getPublicStoriesCollection(lang).doc(storyId);
          final storyDoc = await storyRef.get();
          
          if (storyDoc.exists) {
            await storyRef.update({
              'likeCount': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            break;
          }
        }
      }
    } catch (e) {
      print('Error incrementing like count: $e');
      rethrow;
    }
  }

  // Like count azalt
  Future<void> decrementLikeCount(String storyId, [String? language]) async {
    if (_userId == null) return;
    
    try {
      if (language != null) {
        // Belirli bir dilde ara
        final storyRef = _getPublicStoriesCollection(language).doc(storyId);
        final storyDoc = await storyRef.get();
        
        if (storyDoc.exists) {
          final currentData = storyDoc.data() as Map<String, dynamic>;
          final currentLikes = currentData['likeCount'] ?? 0;
          
          if (currentLikes > 0) {
            await storyRef.update({
              'likeCount': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } else {
        // Tüm dillerde ara
        final languages = ['english', 'turkish', 'spanish', 'french', 'german'];
        
        for (final lang in languages) {
          final storyRef = _getPublicStoriesCollection(lang).doc(storyId);
          final storyDoc = await storyRef.get();
          
          if (storyDoc.exists) {
            final currentData = storyDoc.data() as Map<String, dynamic>;
            final currentLikes = currentData['likeCount'] ?? 0;
            
            if (currentLikes > 0) {
              await storyRef.update({
                'likeCount': FieldValue.increment(-1),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
            break;
          }
        }
      }
    } catch (e) {
      print('Error decrementing like count: $e');
      rethrow;
    }
  }

  // Zorluk seviyeleri
  static const List<String> difficultyLevels = [
    'Beginner',
    'Intermediate', 
    'Advanced'
  ];

  // Popüler tag'ler
  static const List<String> popularTags = [
    'adventure',
    'romance',
    'mystery',
    'fantasy',
    'science-fiction',
    'historical',
    'comedy',
    'drama',
    'educational',
    'short-story'
  ];

  // Author stories verilerini düzelt
  Future<void> fixAuthorStoriesData() async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      print('🔧 Fixing author stories data for user: $userId');
      
      // Tüm dillerde bu kullanıcının hikayelerini bul
      final languages = ['english', 'turkish', 'spanish', 'french', 'german'];
      
      for (final language in languages) {
        print('🔍 Checking $language stories...');
        
        final publicStories = await _firestore
            .collection('stories')
            .doc(language)
            .collection('stories')
            .where('authorId', isEqualTo: userId)
            .get();
        
        print('📖 Found ${publicStories.docs.length} stories in $language');
        
        for (final doc in publicStories.docs) {
          final storyData = doc.data();
          final storyId = doc.id;
          
          print('📝 Processing story: ${storyData['title']} ($storyId)');
          
          // Author stories koleksiyonunda var mı kontrol et
          final authorStoryRef = _firestore
              .collection('stories_by_author')
              .doc(userId)
              .collection('stories')
              .doc(storyId);
              
          final authorStoryDoc = await authorStoryRef.get();
          
          if (!authorStoryDoc.exists) {
            print('➕ Adding missing author story: $storyId');
            
            // Author stories'e ekle
            await authorStoryRef.set({
              'storyId': storyId,
              'language': storyData['language'] ?? language,
              'title': storyData['title'] ?? 'Untitled',
              'isPublished': storyData['isPublished'] ?? true,
              'createdAt': storyData['createdAt'] ?? FieldValue.serverTimestamp(),
            });
          } else {
            print('✅ Author story already exists: $storyId');
          }
        }
      }
      
      print('🎉 Author stories data fix completed!');
    } catch (e) {
      print('❌ Error fixing author stories: $e');
      rethrow;
    }
  }

  // Test hikayelerini sil
  Future<void> deleteTestStories() async {
    try {
      // English test stories
      final englishStories = await _getPublicStoriesCollection('english')
          .where('authorName', isEqualTo: 'Haydar')
          .get();
      
      for (var doc in englishStories.docs) {
        await doc.reference.delete();
        print('🗑️ Deleted English test story: ${doc.id}');
      }

      // Turkish test stories  
      final turkishStories = await _getPublicStoriesCollection('turkish')
          .where('authorName', isEqualTo: 'Haydar')
          .get();
      
      for (var doc in turkishStories.docs) {
        await doc.reference.delete();
        print('🗑️ Deleted Turkish test story: ${doc.id}');
      }

      // Author stories'dan da sil
      if (_userId != null) {
        final authorStories = await _getAuthorStoriesCollection
            .where('authorName', isEqualTo: 'Haydar')
            .get();
        
        for (var doc in authorStories.docs) {
          await doc.reference.delete();
          print('🗑️ Deleted author test story: ${doc.id}');
        }
      }

      print('✅ All test stories deleted successfully!');
    } catch (e) {
      print('❌ Error deleting test stories: $e');
      rethrow;
    }
  }
}
