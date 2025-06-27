import 'package:cloud_firestore/cloud_firestore.dart';

class WordList {
  final String id;
  final String name;
  final String description;
  final int wordCount;
  final DateTime createdAt;
  final String userId; // Added this field

  WordList({
    required this.id,
    required this.name,
    this.description = '',
    required this.wordCount,
    required this.createdAt,
    required this.userId, // Added parameter
  });

  factory WordList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WordList(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      wordCount: data['wordCount'] ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'wordCount': wordCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  WordList copyWith({
    String? id,
    String? name,
    String? description,
    int? wordCount,
    DateTime? createdAt,
    String? userId,
  }) {
    return WordList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}
