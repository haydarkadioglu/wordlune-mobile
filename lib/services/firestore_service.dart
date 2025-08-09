import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/word.dart';
import '../models/list_word.dart';
import '../models/word_list.dart';
import 'language_preference_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LanguagePreferenceService _languageService = LanguagePreferenceService();

  // Kullanıcı ID'sini al
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // Koleksiyon referanslarını al - yeni yapıda dil altında listeler
  // Liste koleksiyonu - sadece liste metadata'sı için
  Future<CollectionReference> _getUserListsCollection() async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');
    
    final selectedLanguage = await LanguagePreferenceService.getSelectedLanguage();
    final languageCode = LanguagePreferenceService.getLanguageCode(selectedLanguage);
    
    print('🔥 FirestoreService Debug:');
    print('   User ID: $userId');
    print('   Selected Language: $selectedLanguage');
    print('   Language Code: $languageCode');
    print('   Lists Path: data/$userId/$languageCode');
    
    return _firestore
        .collection('data')
        .doc(userId)
        .collection(languageCode);
  }

  // Belirli bir liste içindeki kelimeler koleksiyonu
  Future<CollectionReference> _getListWordsCollection(String listId) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');
    
    final selectedLanguage = await LanguagePreferenceService.getSelectedLanguage();
    final languageCode = LanguagePreferenceService.getLanguageCode(selectedLanguage);
    
    print('🔥 Words Collection Path: data/$userId/$languageCode/$listId/words');
    
    return _firestore
        .collection('data')
        .doc(userId)
        .collection(languageCode)
        .doc(listId)
        .collection('words');
  }

  // **LISTE YÖNETİMİ**

  // Tüm listeleri getir
  Stream<List<WordList>> getUserLists() async* {
    final listsCollection = await _getUserListsCollection();
    yield* listsCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => WordList.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Yeni liste oluştur
  Future<String> createWordList(String name, String description) async {
    final listsCollection = await _getUserListsCollection();
    final docRef = await listsCollection.add({
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'wordCount': 0,
    });
    return docRef.id;
  }

  // Liste güncelle
  Future<void> updateWordList(String listId, String name, String description) async {
    final listsCollection = await _getUserListsCollection();
    await listsCollection.doc(listId).update({
      'name': name,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Liste sil
  Future<void> deleteWordList(String listId) async {
    // Önce listedeki tüm kelimeleri sil
    final wordsCollection = await _getListWordsCollection(listId);
    final wordsSnapshot = await wordsCollection.get();
    for (var doc in wordsSnapshot.docs) {
      await doc.reference.delete();
    }
    
    // Sonra listeyi sil
    final listsCollection = await _getUserListsCollection();
    await listsCollection.doc(listId).delete();
  }

  // **KELİME YÖNETİMİ**

  // Belirli bir listedeki kelimeleri getir
  Stream<List<ListWord>> getWordsFromList(String listId) async* {
    final wordsCollection = await _getListWordsCollection(listId);
    yield* wordsCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ListWord.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Tüm listelerden tüm kelimeleri getir
  Stream<List<Word>> getAllWordsFromAllLists() async* {
    final listsCollection = await _getUserListsCollection();
    final listsSnapshot = await listsCollection.get();
    List<Word> allWords = [];

    for (var listDoc in listsSnapshot.docs) {
      final wordsCollection = await _getListWordsCollection(listDoc.id);
      final wordsSnapshot = await wordsCollection.get();
      final words = wordsSnapshot.docs
          .map((doc) => Word.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      allWords.addAll(words);
    }

    yield allWords;
  }

  // Liste içine kelime ekle
  Future<String> addWordToList(String listId, ListWord word) async {
    final wordsCollection = await _getListWordsCollection(listId);
    final docRef = await wordsCollection.add({
      'word': word.word,
      'meaning': word.meaning,
      'exampleSentence': word.exampleSentence,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Liste kelime sayısını güncelle
    await _updateWordCount(listId);
    
    return docRef.id;
  }

  // Kelime güncelle
  Future<void> updateWordInList(String listId, String wordId, ListWord word) async {
    final wordsCollection = await _getListWordsCollection(listId);
    await wordsCollection.doc(wordId).update({
      'word': word.word,
      'meaning': word.meaning,
      'exampleSentence': word.exampleSentence,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Kelime sil
  Future<void> deleteWordFromList(String listId, String wordId) async {
    final wordsCollection = await _getListWordsCollection(listId);
    await wordsCollection.doc(wordId).delete();
    await _updateWordCount(listId);
  }

  // Liste kelime sayısını güncelle
  Future<void> _updateWordCount(String listId) async {
    final wordsCollection = await _getListWordsCollection(listId);
    final wordsSnapshot = await wordsCollection.get();
    final listsCollection = await _getUserListsCollection();
    await listsCollection.doc(listId).update({
      'wordCount': wordsSnapshot.docs.length,
    });
  }

  // **UYUMLULUK METODLARİ (Eski kod için)**
  
  // Eski getUserWords metodu - şimdi tüm listelerden kelimeleri getiriyor
  Stream<List<Word>> getUserWords() {
    return getAllWordsFromAllLists();
  }

  // Eski addWord metodu - varsayılan listeye ekleme yapar
  Future<String> addWord(Word word, {String? defaultListId}) async {
    // Word'u ListWord'e dönüştür
    final listWord = ListWord(
      id: word.id,
      word: word.word,
      meaning: word.meaning,
      exampleSentence: word.example,
      createdAt: word.dateAdded,
    );
    
    if (defaultListId != null) {
      return await addWordToList(defaultListId, listWord);
    } else {
      // Varsayılan bir liste oluştur veya mevcut ilk listeyi kullan
      final listsCollection = await _getUserListsCollection();
      final listsSnapshot = await listsCollection.limit(1).get();
      String listId;
      
      if (listsSnapshot.docs.isEmpty) {
        listId = await createWordList('My Words', 'Default word list');
      } else {
        listId = listsSnapshot.docs.first.id;
      }
      
      return await addWordToList(listId, listWord);
    }
  }

  // Eski updateWord metodu - tüm listelerde kelimeyi arar ve günceller
  Future<void> updateWord(String wordId, Word word) async {
    // Word'u ListWord'e dönüştür
    final listWord = ListWord(
      id: word.id,
      word: word.word,
      meaning: word.meaning,
      exampleSentence: word.example,
      createdAt: word.dateAdded,
    );
    
    final listsCollection = await _getUserListsCollection();
    final listsSnapshot = await listsCollection.get();
    
    for (var listDoc in listsSnapshot.docs) {
      try {
        final wordsCollection = await _getListWordsCollection(listDoc.id);
        final wordDoc = await wordsCollection.doc(wordId).get();
        if (wordDoc.exists) {
          await updateWordInList(listDoc.id, wordId, listWord);
          return;
        }
      } catch (e) {
        continue;
      }
    }
    
    throw Exception('Word not found in any list');
  }

  // Eski deleteWord metodu - tüm listelerde kelimeyi arar ve siler
  Future<void> deleteWord(String wordId) async {
    final listsCollection = await _getUserListsCollection();
    final listsSnapshot = await listsCollection.get();
    
    for (var listDoc in listsSnapshot.docs) {
      try {
        final wordsCollection = await _getListWordsCollection(listDoc.id);
        final wordDoc = await wordsCollection.doc(wordId).get();
        if (wordDoc.exists) {
          await deleteWordFromList(listDoc.id, wordId);
          return;
        }
      } catch (e) {
        continue;
      }
    }
    
    throw Exception('Word not found in any list');
  }

  // Kelime arama (tüm listelerde)
  Future<List<Word>> searchWords(String query) async {
    final listsCollection = await _getUserListsCollection();
    final listsSnapshot = await listsCollection.get();
    List<Word> matchedWords = [];

    for (var listDoc in listsSnapshot.docs) {
      final wordsCollection = await _getListWordsCollection(listDoc.id);
      final wordsSnapshot = await wordsCollection
          .where('word', isGreaterThanOrEqualTo: query)
          .where('word', isLessThan: query + 'z')
          .get();
      
      final words = wordsSnapshot.docs
          .map((doc) => Word.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      matchedWords.addAll(words);
    }

    return matchedWords;
  }

  // Kelime sayısı al (tüm listelerdeki toplam)
  Future<int> getTotalWordCount() async {
    final listsCollection = await _getUserListsCollection();
    final listsSnapshot = await listsCollection.get();
    int totalCount = 0;

    for (var listDoc in listsSnapshot.docs) {
      final wordsCollection = await _getListWordsCollection(listDoc.id);
      final wordsSnapshot = await wordsCollection.get();
      totalCount += wordsSnapshot.docs.length;
    }

    return totalCount;
  }

  // Belirli bir listedeki kelime sayısı
  Future<int> getWordCountInList(String listId) async {
    final wordsCollection = await _getListWordsCollection(listId);
    final wordsSnapshot = await wordsCollection.get();
    return wordsSnapshot.docs.length;
  }

  // Toplu kelime ekleme (belirli bir listeye)
  Future<void> addBulkWordsToList(String listId, List<Word> words) async {
    final batch = _firestore.batch();
    final wordsCollection = await _getListWordsCollection(listId);

    for (var word in words) {
      final docRef = wordsCollection.doc();
      batch.set(docRef, {
        'word': word.word,
        'meaning': word.meaning,
        'pronunciation': word.pronunciation,
        'partOfSpeech': word.partOfSpeech,
        'example': word.example,
        'difficulty': word.difficulty,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    await _updateWordCount(listId);
  }

  // Eski addBulkWords metodu - varsayılan listeye ekler
  Future<void> addBulkWords(List<Word> words, {String? defaultListId}) async {
    if (defaultListId != null) {
      await addBulkWordsToList(defaultListId, words);
    } else {
      // Varsayılan bir liste oluştur veya mevcut ilk listeyi kullan
      final listsCollection = await _getUserListsCollection();
      final listsSnapshot = await listsCollection.limit(1).get();
      String listId;
      
      if (listsSnapshot.docs.isEmpty) {
        listId = await createWordList('My Words', 'Default word list');
      } else {
        listId = listsSnapshot.docs.first.id;
      }
      
      await addBulkWordsToList(listId, words);
    }
  }

  // **EKSİK METODLAR - UYUMLULUK İÇİN**

  // recordLoginHistory metodu
  Future<void> recordLoginHistory() async {
    final userId = _userId;
    if (userId == null) return;
    
    await _firestore.collection('users').doc(userId).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // getListNames metodu - Stream döndürür
  Stream<List<String>> getListNames() async* {
    final listsCollection = await _getUserListsCollection();
    yield* listsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name'] as String? ?? 'Unnamed List';
      }).toList();
    });
  }

  // addWordWithDetails metodu
  Future<String> addWordWithDetails(String word, String meaning, String pronunciation, 
      String partOfSpeech, String example, String difficulty, {String? listId}) async {
    
    final listWordObj = ListWord(
      id: '',
      word: word,
      meaning: meaning,
      exampleSentence: example,
      createdAt: DateTime.now(),
    );
    
    if (listId != null) {
      return await addWordToList(listId, listWordObj);
    } else {
      // Word nesnesi oluşturup addWord'e gönder (addWord içinde ListWord'e dönüştürülecek)
      final wordObj = Word(
        id: '',
        text: word,
        meaning: meaning,
        pronunciationText: pronunciation,
        exampleSentence: example,
        category: difficulty,
        dateAdded: DateTime.now(),
        language: await LanguagePreferenceService.getSelectedLanguage(),
      );
      return await addWord(wordObj);
    }
  }

  // getLists metodu (getUserLists için alias)
  Stream<List<WordList>> getLists() {
    return getUserLists();
  }

  // addList metodu (createWordList için alias)
  Future<String> addList(String name, {String description = ''}) async {
    return await createWordList(name, description);
  }

  // getWords metodu (getAllWordsFromAllLists için alias)
  Stream<List<Word>> getWords() {
    return getAllWordsFromAllLists();
  }

  // updateWordCategory metodu
  Future<void> updateWordCategory(String wordId, String category) async {
    final listsCollection = await _getUserListsCollection();
    final listsSnapshot = await listsCollection.get();
    
    for (var listDoc in listsSnapshot.docs) {
      try {
        final wordsCollection = await _getListWordsCollection(listDoc.id);
        final wordDoc = await wordsCollection.doc(wordId).get();
        if (wordDoc.exists) {
          await wordsCollection.doc(wordId).update({
            'category': category,
            'difficulty': category,
            'partOfSpeech': category,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return;
        }
      } catch (e) {
        continue;
      }
    }
  }

  // createList metodu (createWordList için alias)
  Future<String> createList(String name, String description) async {
    return await createWordList(name, description);
  }

  // deleteList metodu (deleteWordList için alias)
  Future<void> deleteList(String listId) async {
    return await deleteWordList(listId);
  }

  // countWordsInList metodu - Stream döndürür
  Stream<int> countWordsInList(String listId) async* {
    final wordsCollection = await _getListWordsCollection(listId);
    yield* wordsCollection.snapshots().map((snapshot) => snapshot.docs.length);
  }

  // getWordsInList metodu (getWordsFromList için alias)
  Stream<List<ListWord>> getWordsInList(String listId) {
    return getWordsFromList(listId);
  }

  // getRecentWords metodu - Stream döndürür
  Stream<List<Word>> getRecentWords({int limit = 10}) async* {
    final listsCollection = await _getUserListsCollection();
    final listsSnapshot = await listsCollection.get();
    List<Word> allWords = [];

    for (var listDoc in listsSnapshot.docs) {
      final wordsCollection = await _getListWordsCollection(listDoc.id);
      final wordsSnapshot = await wordsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      final words = wordsSnapshot.docs
          .map((doc) => Word.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      allWords.addAll(words);
    }

    // Sort by creation date and limit
    allWords.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    yield allWords.take(limit).toList();
  }

  // updateListWord metodu
  Future<void> updateListWord(String listId, String wordId, Word word) async {
    // Word'u ListWord'e dönüştür
    final listWord = ListWord(
      id: word.id,
      word: word.word,
      meaning: word.meaning,
      exampleSentence: word.example,
      createdAt: word.dateAdded,
    );
    return await updateWordInList(listId, wordId, listWord);
  }

  // updateWordDetails metodu
  Future<void> updateWordDetails(String wordId, String word, String meaning, 
      String pronunciation, String example, String category) async {
    
    final wordObj = Word(
      id: wordId,
      text: word,
      meaning: meaning,
      pronunciationText: pronunciation,
      exampleSentence: example,
      category: category,
      dateAdded: DateTime.now(),
      language: await LanguagePreferenceService.getSelectedLanguage(),
    );
    
    await updateWord(wordId, wordObj);
  }
}
