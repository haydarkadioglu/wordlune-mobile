import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'language_preference_service.dart';

class MigrationService {
  static final _db = FirebaseFirestore.instance;
  static User? get _user => FirebaseAuth.instance.currentUser;

  // Migrate existing data to new language-based structure
  static Future<void> migrateToLanguageBasedStructure() async {
    if (_user == null) return;

    try {
      final userId = _user!.uid;
      final selectedLanguage = await LanguagePreferenceService.getSelectedLanguage();
      final languageCode = LanguagePreferenceService.getLanguageCode(selectedLanguage);

      // Migrate words
      await _migrateWords(userId, languageCode);
      
      // Migrate lists
      await _migrateLists(userId, languageCode);
      
      print('Migration completed successfully');
    } catch (e) {
      print('Migration failed: $e');
      rethrow;
    }
  }

  // Migrate words from old structure to new language-based structure
  static Future<void> _migrateWords(String userId, String languageCode) async {
    try {
      // Get all words from old structure
      final oldWordsSnapshot = await _db
          .collection('data')
          .doc(userId)
          .collection('words')
          .get();

      if (oldWordsSnapshot.docs.isEmpty) {
        print('No words to migrate');
        return;
      }

      // Create new language-based collection
      final newWordsCollection = _db
          .collection('data')
          .doc(userId)
          .collection('words');

      // Migrate each word
      final batch = _db.batch();
      for (final doc in oldWordsSnapshot.docs) {
        final data = doc.data();
        data['language'] = LanguagePreferenceService.getLanguageName(languageCode);
        
        final newDocRef = newWordsCollection.doc();
        batch.set(newDocRef, data);
      }

      await batch.commit();
      print('Migrated ${oldWordsSnapshot.docs.length} words');
    } catch (e) {
      print('Error migrating words: $e');
      rethrow;
    }
  }

  // Migrate lists from old structure to new language-based structure
  static Future<void> _migrateLists(String userId, String languageCode) async {
    try {
      // Get all lists from old structure
      final oldListsSnapshot = await _db
          .collection('data')
          .doc(userId)
          .collection('lists')
          .get();

      if (oldListsSnapshot.docs.isEmpty) {
        print('No lists to migrate');
        return;
      }

      // Create new language-based collection
      final newListsCollection = _db
          .collection('data')
          .doc(userId)
          .collection('lists');

      // Migrate each list
      final batch = _db.batch();
      for (final doc in oldListsSnapshot.docs) {
        final data = doc.data();
        data['language'] = LanguagePreferenceService.getLanguageName(languageCode);
        
        final newDocRef = newListsCollection.doc();
        batch.set(newDocRef, data);

        // Migrate words in this list
        await _migrateListWords(userId, doc.id, newDocRef.id, languageCode);
      }

      await batch.commit();
      print('Migrated ${oldListsSnapshot.docs.length} lists');
    } catch (e) {
      print('Error migrating lists: $e');
      rethrow;
    }
  }

  // Migrate words within a list
  static Future<void> _migrateListWords(
    String userId, 
    String oldListId, 
    String newListId, 
    String languageCode
  ) async {
    try {
      // Get all words from old list
      final oldWordsSnapshot = await _db
          .collection('data')
          .doc(userId)
          .collection('lists')
          .doc(oldListId)
          .collection('words')
          .get();

      if (oldWordsSnapshot.docs.isEmpty) {
        return;
      }

      // Create new list words collection
      final newWordsCollection = _db
          .collection('data')
          .doc(userId)
          .collection('lists')
          .doc(newListId)
          .collection('words');

      // Migrate each word
      final batch = _db.batch();
      for (final doc in oldWordsSnapshot.docs) {
        final data = doc.data();
        data['language'] = LanguagePreferenceService.getLanguageName(languageCode);
        
        final newDocRef = newWordsCollection.doc();
        batch.set(newDocRef, data);
      }

      await batch.commit();
      print('Migrated ${oldWordsSnapshot.docs.length} words in list $oldListId');
    } catch (e) {
      print('Error migrating list words: $e');
      rethrow;
    }
  }

  // Check if migration is needed
  static Future<bool> isMigrationNeeded() async {
    if (_user == null) return false;

    try {
      final userId = _user!.uid;
      
      // Check if old structure exists
      final oldWordsSnapshot = await _db
          .collection('data')
          .doc(userId)
          .collection('words')
          .limit(1)
          .get();

      return oldWordsSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking migration status: $e');
      return false;
    }
  }

  // Clean up old data after successful migration
  static Future<void> cleanupOldData() async {
    if (_user == null) return;

    try {
      final userId = _user!.uid;
      
      // Delete old words collection
      await _deleteCollection(
        _db.collection('data').doc(userId).collection('words')
      );
      
      // Delete old lists collection
      await _deleteCollection(
        _db.collection('data').doc(userId).collection('lists')
      );
      
      print('Old data cleaned up successfully');
    } catch (e) {
      print('Error cleaning up old data: $e');
      rethrow;
    }
  }

  // Helper method to delete a collection
  static Future<void> _deleteCollection(CollectionReference collection) async {
    final snapshot = await collection.get();
    final batch = _db.batch();
    
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
} 