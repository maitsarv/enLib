import 'package:flutter/foundation.dart';

@immutable
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.authorId,
    this.isbn = '',
    this.year,
    this.notes = '',
  });

  final String id;
  final String title;
  final String authorId;
  final String isbn;
  final int? year;
  final String notes;

  Book copyWith({
    String? title,
    String? authorId,
    String? isbn,
    int? year,
    bool clearYear = false,
    String? notes,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      authorId: authorId ?? this.authorId,
      isbn: isbn ?? this.isbn,
      year: clearYear ? null : (year ?? this.year),
      notes: notes ?? this.notes,
    );
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      authorId: (json['authorId'] as String?) ?? '',
      isbn: (json['isbn'] as String?) ?? '',
      year: json['year'] as int?,
      notes: (json['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'authorId': authorId,
      'isbn': isbn,
      'year': year,
      'notes': notes,
    };
  }
}
