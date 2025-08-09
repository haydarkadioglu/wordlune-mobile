import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/word_list.dart';
import '../models/list_word.dart';

class WordListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get user's word lists
  Stream<List<WordList>> getUserWordLists() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('wordLists')
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WordList.fromFirestore(doc))
            .toList());
  }

  // Get default word list for user (or create one)
  Future<WordList> getOrCreateDefaultWordList(String language) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Try to find existing default list for this language
    final querySnapshot = await _firestore
        .collection('wordLists')
        .where('userId', isEqualTo: _currentUserId)
        .where('language', isEqualTo: language)
        .where('name', isEqualTo: 'My Words - $language')
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return WordList.fromFirestore(querySnapshot.docs.first);
    }

    // Create new default list
    final newList = WordList(
      id: '', // Will be set by Firestore
      name: 'My Words - $language',
      description: 'Words collected from stories',
      wordCount: 0,
      createdAt: DateTime.now(),
      userId: _currentUserId!,
      language: language,
    );

    final docRef = await _firestore
        .collection('wordLists')
        .add(newList.toFirestore());

    return newList.copyWith(id: docRef.id);
  }

  // Add word to list
  Future<void> addWordToList(String listId, String word, String meaning, {String? storyTitle}) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Check if word already exists in this list
    final existingWord = await _firestore
        .collection('wordLists')
        .doc(listId)
        .collection('words')
        .where('word', isEqualTo: word.toLowerCase())
        .limit(1)
        .get();

    if (existingWord.docs.isNotEmpty) {
      // Word already exists, don't add again
      return;
    }

    // Add the word
    final listWord = ListWord(
      id: '', // Will be set by Firestore
      word: word,
      meaning: meaning,
      exampleSentence: storyTitle != null ? 'From story: $storyTitle' : '',
      language: 'Turkish', // Default to Turkish, can be made dynamic
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('wordLists')
        .doc(listId)
        .collection('words')
        .add(listWord.toFirestore());

    // Update word count in the list
    await _firestore
        .collection('wordLists')
        .doc(listId)
        .update({
      'wordCount': FieldValue.increment(1),
    });
  }

  // Get words from a list
  Stream<List<ListWord>> getWordsFromList(String listId) {
    return _firestore
        .collection('wordLists')
        .doc(listId)
        .collection('words')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ListWord.fromFirestore(doc))
            .toList());
  }

  // Remove word from list
  Future<void> removeWordFromList(String listId, String wordId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('wordLists')
        .doc(listId)
        .collection('words')
        .doc(wordId)
        .delete();

    // Update word count in the list
    await _firestore
        .collection('wordLists')
        .doc(listId)
        .update({
      'wordCount': FieldValue.increment(-1),
    });
  }

  // Create a new word list
  Future<WordList> createWordList(String name, String description, String language) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final newList = WordList(
      id: '', // Will be set by Firestore
      name: name,
      description: description,
      wordCount: 0,
      createdAt: DateTime.now(),
      userId: _currentUserId!,
      language: language,
    );

    final docRef = await _firestore
        .collection('wordLists')
        .add(newList.toFirestore());

    return newList.copyWith(id: docRef.id);
  }

  // Delete a word list
  Future<void> deleteWordList(String listId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Delete all words in the list first
    final wordsSnapshot = await _firestore
        .collection('wordLists')
        .doc(listId)
        .collection('words')
        .get();

    final batch = _firestore.batch();
    for (final doc in wordsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Delete the list itself
    await _firestore
        .collection('wordLists')
        .doc(listId)
        .delete();
  }
}
