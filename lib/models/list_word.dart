import 'package:cloud_firestore/cloud_firestore.dart';

class ListWord {
  final String id;
  final String word;
  final String meaning;
  final String exampleSentence;
  final String language;
  final DateTime createdAt;

  ListWord({
    required this.id,
    required this.word,
    required this.meaning,
    required this.exampleSentence,
    this.language = 'Turkish',
    required this.createdAt,
  });

  factory ListWord.fromMap(Map<String, dynamic> data, String id) {
    DateTime createdAtDate = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0);
        
    return ListWord(
      id: id,
      word: data['word'] ?? '',
      meaning: data['meaning'] ?? '',
      exampleSentence: data['exampleSentence'] ?? '',
      language: data['language'] ?? 'Turkish',
      createdAt: createdAtDate,
    );
  }

  factory ListWord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListWord.fromMap(data, doc.id);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'word': word,
      'meaning': meaning,
      'exampleSentence': exampleSentence,
      'language': language,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
