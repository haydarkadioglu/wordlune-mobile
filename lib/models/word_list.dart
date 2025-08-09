import 'package:cloud_firestore/cloud_firestore.dart';

class WordList {
  final String id;
  final String name;
  final String description;
  final int wordCount;
  final DateTime createdAt;
  final String userId;
  final String language; // Added language field

  WordList({
    required this.id,
    required this.name,
    this.description = '',
    required this.wordCount,
    required this.createdAt,
    required this.userId,
    required this.language, // Added parameter
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
      language: data['language'] ?? 'Turkish', // Added language field
    );
  }

  factory WordList.fromMap(Map<String, dynamic> data, String id) {
    DateTime createdDate;
    
    // Handle different date formats
    if (data['createdAt'] is Timestamp) {
      createdDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is int) {
      createdDate = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
    } else if (data['createdAt'] is String) {
      createdDate = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    } else {
      createdDate = DateTime.now();
    }
    
    return WordList(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      wordCount: data['wordCount'] ?? 0,
      createdAt: createdDate,
      userId: data['userId'] ?? '',
      language: data['language'] ?? 'Turkish',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'wordCount': wordCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'language': language, // Added language field
    };
  }

  WordList copyWith({
    String? id,
    String? name,
    String? description,
    int? wordCount,
    DateTime? createdAt,
    String? userId,
    String? language, // Added language parameter
  }) {
    return WordList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      language: language ?? this.language, // Added language field
    );
  }
}
