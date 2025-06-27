import 'package:cloud_firestore/cloud_firestore.dart';

class Word {
  final String id;
  final String text; // Changed from 'word' to 'text'
  final String meaning; // Changed from 'translation' to 'meaning'
  final String pronunciationText; // Changed from 'ipa' to 'pronunciationText'
  final String exampleSentence; // Changed from 'example' to 'exampleSentence'
  final String category; // 'Very Good', 'Good', 'Bad'
  final DateTime dateAdded; // Changed from 'dateAdded' to 'createdAt' in Firestore

  Word({
    required this.id,
    required this.text,
    required this.meaning,
    required this.pronunciationText,
    required this.exampleSentence,
    required this.category,
    required this.dateAdded,
  });

  // Factory constructor for Firestore data
  factory Word.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime createdDate;
    
    // Handle different createdAt formats
    if (data['createdAt'] is Timestamp) {
      createdDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is int) {
      createdDate = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
    } else if (data['createdAt'] is String) {
      createdDate = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    } else {
      createdDate = DateTime.now();
    }
    
    return Word(
      id: id,
      text: data['text'] ?? '',
      meaning: data['meaning'] ?? '',
      pronunciationText: data['pronunciationText'] ?? '',
      exampleSentence: data['exampleSentence'] ?? '',
      category: data['category'] ?? 'Good',
      dateAdded: createdDate,
    );
  }

  // Legacy method for backward compatibility (if needed)
  factory Word.fromMap(String id, Map<String, dynamic> data) {
    return Word(
      id: id,
      text: data['word'] ?? data['text'] ?? '',
      meaning: data['translation'] ?? data['meaning'] ?? '',
      pronunciationText: data['ipa'] ?? data['pronunciationText'] ?? '',
      exampleSentence: data['example'] ?? data['exampleSentence'] ?? '',
      category: data['category'] ?? 'Good',
      dateAdded: data['dateAdded'] is Timestamp 
          ? (data['dateAdded'] as Timestamp).toDate()
          : data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'meaning': meaning,
      'pronunciationText': pronunciationText,
      'exampleSentence': exampleSentence,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Legacy method for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'word': text,
      'translation': meaning,
      'ipa': pronunciationText,
      'example': exampleSentence,
      'category': category,
      'dateAdded': dateAdded,
    };
  }

  // Getter methods for backward compatibility
  String get word => text;
  String get translation => meaning;
  String get ipa => pronunciationText;
  String get example => exampleSentence;

  // Copy with method for updates
  Word copyWith({
    String? id,
    String? text,
    String? meaning,
    String? pronunciationText,
    String? exampleSentence,
    String? category,
    DateTime? dateAdded,
  }) {
    return Word(
      id: id ?? this.id,
      text: text ?? this.text,
      meaning: meaning ?? this.meaning,
      pronunciationText: pronunciationText ?? this.pronunciationText,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      category: category ?? this.category,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
} 