import 'package:cloud_firestore/cloud_firestore.dart';

class ListWord {
  final String id;
  final String word;
  final String meaning;
  final String example;
  final String language;
  final DateTime createdAt;
  final DateTime addedAt; // Added this field

  ListWord({
    required this.id,
    required this.word,
    required this.meaning,
    required this.example,
    this.language = 'Turkish',
    required this.createdAt,
    DateTime? addedAt, // Added parameter
  }) : this.addedAt = addedAt ?? createdAt; // Default to createdAt if not specified

  factory ListWord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime createdAtDate = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0);
        
    return ListWord(
      id: doc.id,
      word: data['word'] ?? '',
      meaning: data['meaning'] ?? '',
      example: data['example'] ?? '',
      language: data['language'] ?? 'Turkish',
      createdAt: createdAtDate,
      addedAt: data['addedAt'] is Timestamp
          ? (data['addedAt'] as Timestamp).toDate()
          : createdAtDate, // Default to createdAt if addedAt doesn't exist
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'word': word,
      'meaning': meaning,
      'example': example,
      'language': language,
      'createdAt': Timestamp.fromDate(createdAt),
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}
