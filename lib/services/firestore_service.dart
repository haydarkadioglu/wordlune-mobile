import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/word.dart';
import '../models/word_list.dart';
import '../models/list_word.dart';
import 'gemini_service.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _geminiService = GeminiService();
  
  // Get current user dynamically
  User? get _user => FirebaseAuth.instance.currentUser;

  // User's words collection reference
  CollectionReference get _userWordsCollection {
    final user = _user;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _db.collection('data').doc(user.uid).collection('words');
  }

  // User's lists collection reference
  CollectionReference get _userListsCollection {
    final user = _user;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _db.collection('data').doc(user.uid).collection('lists');
  }

  // Get AI details using Gemini service
  Future<Map<String, String>> getAIDetails(String word) async {
    try {
      final details = await _geminiService.getWordDetails(word);
      final translation = details['translation'] ?? 'Çeviri bulunamadı';
      final example = details['example'] ?? 'Örnek cümle bulunamadı';
      
      return {
        'meaning': translation,
        'pronunciationText': '/$word/',
        'exampleSentence': example,
      };
    } catch (e) {
      // Fallback to basic translation if Gemini fails
      final translation = await _geminiService.translateWord(word);
      return {
        'meaning': translation,
        'pronunciationText': '/$word/',
        'exampleSentence': 'Example sentence for $word',
      };
    }
  }

  // Add a word to user's main words collection
  Future<void> addWord(String word, {String category = 'Good'}) async {
    if (_user == null) throw Exception('User not authenticated');
    
    final ai = await getAIDetails(word);
    await _userWordsCollection.add({
      'text': word,
      'meaning': ai['meaning'],
      'pronunciationText': ai['pronunciationText'],
      'exampleSentence': ai['exampleSentence'],
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Add word with custom details
  Future<void> addWordWithDetails({
    required String word,
    required String translation,
    required String ipa,
    required String example,
    required String category,
    String? listId,
    String language = 'Turkish', // Add language parameter with default
  }) async {
    if (_user == null) throw Exception('User not authenticated');
    
    if (listId != null && listId.isNotEmpty) {
      // Add to specific list
      await addWordToList(
        listId: listId,
        word: word,
        meaning: translation,
        example: example,
        language: language, // Pass language parameter
      );
    } else {
      // Add to main words collection
      await _userWordsCollection.add({
        'text': word,
        'meaning': translation,
        'pronunciationText': ipa,
        'exampleSentence': example,
        'category': category,
        'language': language, // Add language field
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get all user's words from main collection
  Stream<List<Word>> getWords() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Stream.value([]);
    }
    
    return _userWordsCollection
        .snapshots()
        .map((snapshot) {
          final words = snapshot.docs
              .map((doc) {
                try {
                  return Word.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
                } catch (e) {
                  return null;
                }
              })
              .where((word) => word != null)
              .cast<Word>()
              .toList();
          
          // Sort by date after parsing (safer than Firestore orderBy)
          words.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
          
          return words;
        });
  }

  // Update word category
  Future<void> updateWordCategory(String wordId, String category) async {
    if (_user == null) throw Exception('User not authenticated');
    
    await _userWordsCollection.doc(wordId).update({'category': category});
  }

  // Delete word
  Future<void> deleteWord(String wordId) async {
    if (_user == null) throw Exception('User not authenticated');
    
    await _userWordsCollection.doc(wordId).delete();
  }

  // Create a new list
  Future<String> addList(String listName) async {
    if (_user == null) throw Exception('User not authenticated');
    
    final docRef = await _userListsCollection.add({
      'name': listName,
      'description': '',
      'wordCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': _user!.uid, // Add the userId field
    });
    
    return docRef.id;
  }

  // Create a new list with name and optional description
  Future<String> createList(String listName, {String description = ''}) async {
    if (_user == null) throw Exception('User not authenticated');
    
    final docRef = await _userListsCollection.add({
      'name': listName,
      'description': description,
      'wordCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': _user!.uid, // Add the userId field
    });
    
    return docRef.id;
  }

  // Get all user's lists
  Stream<List<WordList>> getLists() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Stream.value([]);
    }
    
    return _userListsCollection
        .snapshots()
        .map((snapshot) {
          final lists = snapshot.docs
              .map((doc) {
                try {
                  return WordList.fromFirestore(doc);
                } catch (e) {
                  return null;
                }
              })
              .where((list) => list != null)
              .cast<WordList>()
              .toList();
          
          // Sort by date after parsing
          lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return lists;
        });
  }

  // Stream for getting word count from a list - NEW METHOD
  Stream<int> countWordsInList(String listId) {
    if (_user == null) return Stream.value(0);
    
    return _userListsCollection
        .doc(listId)
        .snapshots()
        .map((doc) => doc.exists ? (doc.data() as Map<String, dynamic>)['wordCount'] as int? ?? 0 : 0);
  }

  // Get words from a list with sorting options - NEW METHOD
  Stream<List<ListWord>> getWordsInList(String listId) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Stream.value([]);
    }
    
    return _userListsCollection
        .doc(listId)
        .collection('words')
        .snapshots()
        .map((snapshot) {
          final words = snapshot.docs
              .map((doc) {
                try {
                  return ListWord.fromFirestore(doc);
                } catch (e) {
                  print('Error parsing word: ${e.toString()}');
                  return null;
                }
              })
              .where((word) => word != null)
              .cast<ListWord>()
              .toList();
          
          return words;
        });
  }

  // Update word in a list - NEW METHOD
  Future<void> updateWord(ListWord updatedWord) async {
    if (_user == null) throw Exception('User not authenticated');
    
    // Extract list ID and word ID from the path or compound ID
    final listIdParts = updatedWord.id.split('/');
    String listId = '';
    String wordId = '';
    
    if (listIdParts.length > 1) {
      // Complex ID with list and word IDs
      listId = listIdParts[0];
      wordId = listIdParts[1];
    } else {
      // Simple ID, assuming it's the word ID
      wordId = updatedWord.id;
      // You would need the list ID from elsewhere
      throw Exception('List ID must be provided to update a word');
    }
    
    final updates = {
      'word': updatedWord.word,
      'meaning': updatedWord.meaning,
      'example': updatedWord.example,
      'language': updatedWord.language,
      'addedAt': Timestamp.fromDate(updatedWord.addedAt),
    };
    
    await _userListsCollection
        .doc(listId)
        .collection('words')
        .doc(wordId)
        .update(updates);
  }

  // Update word list details - NEW METHOD
  Future<void> updateWordList(WordList updatedList) async {
    if (_user == null) throw Exception('User not authenticated');
    
    await _userListsCollection.doc(updatedList.id).update({
      'name': updatedList.name,
      'description': updatedList.description,
      'userId': updatedList.userId, // Ensure userId is included
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a word list - NEW METHOD
  Future<void> deleteWordList(String listId) async {
    if (_user == null) throw Exception('User not authenticated');
    
    // This is the same as deleteList, but renamed for consistency
    await deleteList(listId);
  }
  
  // Add bulk words to a list - NEW METHOD
  Future<void> addBulkWords(List<String> words, {String? listId}) async {
    if (_user == null) throw Exception('User not authenticated');
    
    if (listId != null && listId.isNotEmpty) {
      // Use existing bulk add method with the list ID
      await bulkAddWords(words, listId: listId);
    } else {
      // If no list ID provided, add to main words collection
      await bulkAddWords(words);
    }
  }

  // Get list names only (for dropdowns)
  Stream<List<String>> getListNames() {
    if (_user == null) return Stream.value([]);
    
    return _userListsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String)
            .toList());
  }

  // Add word to specific list
  Future<void> addWordToList({
    required String listId,
    required String word,
    required String meaning,
    required String example,
    String language = 'Turkish',
  }) async {
    if (_user == null) throw Exception('User not authenticated');
    
    // Add word to list's words subcollection
    await _userListsCollection
        .doc(listId)
        .collection('words')
        .add({
      'word': word,
      'meaning': meaning,
      'example': example,
      'language': language,
      'createdAt': FieldValue.serverTimestamp(),
      'addedAt': FieldValue.serverTimestamp(), // Add the addedAt field
    });

    // Update list word count
    await _userListsCollection.doc(listId).update({
      'wordCount': FieldValue.increment(1),
    });
  }

  // Add word to specific list with AI details
  Future<void> addWordToListSimple(String listId, String word) async {
    if (_user == null) throw Exception('User not authenticated');
    
    final ai = await getAIDetails(word);
    
    await addWordToList(
      listId: listId,
      word: word,
      meaning: ai['meaning'] ?? '',
      example: ai['exampleSentence'] ?? '',
    );
  }

  // Get words from specific list
  Stream<List<ListWord>> getListWords(String listId) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Stream.value([]);
    }
    
    return _userListsCollection
        .doc(listId)
        .collection('words')
        .snapshots()
        .map((snapshot) {
          final words = snapshot.docs
              .map((doc) {
                try {
                  return ListWord.fromFirestore(doc);
                } catch (e) {
                  return null;
                }
              })
              .where((word) => word != null)
              .cast<ListWord>()
              .toList();
          
          // Sort by date after parsing
          words.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return words;
        });
  }

  // Delete word from list
  Future<void> deleteWordFromList(String listId, String wordId) async {
    if (_user == null) throw Exception('User not authenticated');
    
    await _userListsCollection
        .doc(listId)
        .collection('words')
        .doc(wordId)
        .delete();

    // Update list word count
    await _userListsCollection.doc(listId).update({
      'wordCount': FieldValue.increment(-1),
    });
  }

  // Delete entire list
  Future<void> deleteList(String listId) async {
    if (_user == null) throw Exception('User not authenticated');
    
    // First delete all words in the list
    final wordsSnapshot = await _userListsCollection
        .doc(listId)
        .collection('words')
        .get();
    
    final batch = _db.batch();
    for (final doc in wordsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete the list document
    batch.delete(_userListsCollection.doc(listId));
    
    await batch.commit();
  }

  // Bulk add words to main collection
  Future<void> bulkAddWords(
    List<String> words, {
    String category = 'Good',
    String? listId,
  }) async {
    if (_user == null) throw Exception('User not authenticated');
    
    final batch = _db.batch();
    
    for (final word in words) {
      final ai = await getAIDetails(word);
      
      if (listId != null && listId.isNotEmpty) {
        // Add to specific list
        final listWordRef = _userListsCollection
            .doc(listId)
            .collection('words')
            .doc();
        
        batch.set(listWordRef, {
          'word': word,
          'meaning': ai['meaning'],
          'example': ai['exampleSentence'],
          'language': 'Turkish',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add to main words collection
        final wordRef = _userWordsCollection.doc();
        batch.set(wordRef, {
          'text': word,
          'meaning': ai['meaning'],
          'pronunciationText': ai['pronunciationText'],
          'exampleSentence': ai['exampleSentence'],
          'category': category,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    
    // Update list word count if adding to list
    if (listId != null && listId.isNotEmpty) {
      batch.update(_userListsCollection.doc(listId), {
        'wordCount': FieldValue.increment(words.length),
      });
    }
    
    await batch.commit();
  }

  // Record user login history
  Future<void> recordLoginHistory() async {
    if (_user == null) return;
    
    try {
      await _db
          .collection('data')
          .doc(_user!.uid)
          .collection('loginHistory')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'userAgent': 'Flutter Mobile App', // You can get real user agent if needed
        'platform': 'Mobile', // You can detect actual platform
      });
      
      // Keep only last 25 entries
      final historySnapshot = await _db
          .collection('data')
          .doc(_user!.uid)
          .collection('loginHistory')
          .orderBy('timestamp', descending: true)
          .get();
      
      if (historySnapshot.docs.length > 25) {
        final batch = _db.batch();
        for (int i = 25; i < historySnapshot.docs.length; i++) {
          batch.delete(historySnapshot.docs[i].reference);
        }
        await batch.commit();
      }
    } catch (e) {
      // Silently fail login history recording
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    if (_user == null) return {};
    
    try {
      final wordsSnapshot = await _userWordsCollection.get();
      final listsSnapshot = await _userListsCollection.get();
      
      final words = wordsSnapshot.docs
          .map((doc) => Word.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      final monthAgo = DateTime(now.year, now.month - 1, now.day);
      
      final todayWords = words.where((w) => 
        w.dateAdded.isAfter(today)).length;
      final weekWords = words.where((w) => 
        w.dateAdded.isAfter(weekAgo)).length;
      final monthWords = words.where((w) => 
        w.dateAdded.isAfter(monthAgo)).length;
      
      final veryGoodCount = words.where((w) => w.category == 'Very Good').length;
      final goodCount = words.where((w) => w.category == 'Good').length;
      final badCount = words.where((w) => w.category == 'Bad').length;
      
      return {
        'totalWords': words.length,
        'totalLists': listsSnapshot.docs.length,
        'todayWords': todayWords,
        'weekWords': weekWords,
        'monthWords': monthWords,
        'veryGoodCount': veryGoodCount,
        'goodCount': goodCount,
        'badCount': badCount,
      };
    } catch (e) {
      return {};
    }
  }

  // Update list details
  Future<void> updateList({
    required String listId,
    String? name,
    String? description,
    WordList? list,
  }) async {
    if (_user == null) throw Exception('User not authenticated');
    
    final updates = <String, dynamic>{};
    
    if (list != null) {
      updates['name'] = list.name;
      updates['description'] = list.description;
    } else {
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
    }
    
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _userListsCollection.doc(listId).update(updates);
  }

  // Update word in list
  Future<void> updateListWord({
    required String listId,
    required String wordId,
    required String word,
    required String meaning,
    String? example,
    String language = 'Turkish', // Dil parametresi ekledik
  }) async {
    if (_user == null) throw Exception('User not authenticated');
    
    await _userListsCollection
        .doc(listId)
        .collection('words')
        .doc(wordId)
        .update({
      'word': word,
      'meaning': meaning,
      'language': language, // Dil bilgisini güncelle
      if (example != null) 'example': example,
    });
  }

  // Delete word from list
  Future<void> deleteListWord(String listId, String wordId) async {
    if (_user == null) throw Exception('User not authenticated');
    
    await _userListsCollection
        .doc(listId)
        .collection('words')
        .doc(wordId)
        .delete();
        
    // Update word count
    await _userListsCollection.doc(listId).update({
      'wordCount': FieldValue.increment(-1),
    });
  }

  // Get recent words for the current user
  Stream<List<Word>> getRecentWords({int limit = 5}) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _db
        .collection('data')
        .doc(userId)
        .collection('words')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Word.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Add bulk words to a specific list
  Future<void> addBulkWordsToList({
    required String listId,
    required List<Map<String, dynamic>> words,
  }) async {
    if (_user == null) throw Exception('User not authenticated');
    
    // Get a reference to the list document
    final listRef = _userListsCollection.doc(listId);
    
    // Start a batch write
    final batch = _db.batch();
    
    // Add each word to the list's words subcollection
    for (final word in words) {
      final wordRef = listRef.collection('words').doc();
      final wordData = {
        'word': word['word'],
        'meaning': word['meaning'],
        'example': word['example'] ?? '',
        'language': word['language'] ?? 'Turkish',
        'createdAt': FieldValue.serverTimestamp(),
        'addedAt': FieldValue.serverTimestamp(),
      };
      batch.set(wordRef, wordData);
    }
    
    // Update the wordCount field in the list document
    await _db.runTransaction((transaction) async {
      final listDoc = await transaction.get(listRef);
      if (listDoc.exists) {
        final listData = listDoc.data() as Map<String, dynamic>;
        final currentCount = listData['wordCount'] as int? ?? 0;
        transaction.update(listRef, {'wordCount': currentCount + words.length});
      }
    });
    
    // Commit the batch
    await batch.commit();
  }

  // Update word
  Future<void> updateWordDetails(String wordId, {
    String? text,
    String? meaning,
    String? example,
    String? category,
  }) async {
    if (_user == null) throw Exception('User not authenticated');
    
    final Map<String, dynamic> updateData = {};
    if (text != null) updateData['text'] = text;
    if (meaning != null) updateData['meaning'] = meaning;
    if (example != null) updateData['example'] = example;
    if (category != null) updateData['category'] = category;
    
    await _userWordsCollection.doc(wordId).update(updateData);
  }
}