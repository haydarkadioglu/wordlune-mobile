import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final bool isPublished;
  final String language;
  final String level; // A1 | A2 | B1 | B2 | C1 | C2
  final String category; // Fiction | Non-Fiction | News | Academic | etc.
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final int likeCount;

  Story({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.isPublished,
    required this.language,
    required this.level,
    required this.category,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.likeCount = 0,
  });

  factory Story.fromMap(Map<String, dynamic> map, String id) {
    return Story(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      isPublished: map['isPublished'] ?? false,
      language: map['language'] ?? '',
      level: map['level'] ?? 'A1',
      category: map['category'] ?? 'General',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewCount: map['viewCount'] ?? 0,
      likeCount: map['likeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'isPublished': isPublished,
      'language': language,
      'level': level,
      'category': category,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'viewCount': viewCount,
      'likeCount': likeCount,
    };
  }

  Story copyWith({
    String? title,
    String? content,
    bool? isPublished,
    String? level,
    String? category,
    List<String>? tags,
    DateTime? updatedAt,
    int? viewCount,
    int? likeCount,
  }) {
    return Story(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId,
      authorName: authorName,
      isPublished: isPublished ?? this.isPublished,
      language: language,
      level: level ?? this.level,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}

class AuthorStory {
  final String storyId;
  final String language;
  final String title;
  final bool isPublished;
  final DateTime createdAt;

  AuthorStory({
    required this.storyId,
    required this.language,
    required this.title,
    required this.isPublished,
    required this.createdAt,
  });

  factory AuthorStory.fromMap(Map<String, dynamic> map, String id) {
    return AuthorStory(
      storyId: id,
      language: map['language'] ?? '',
      title: map['title'] ?? '',
      isPublished: map['isPublished'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storyId': storyId,
      'language': language,
      'title': title,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
