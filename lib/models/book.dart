import 'package:flutter/foundation.dart';

@immutable
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.year,
    this.rating,
    this.notes = '',
  });

  final String id;
  final String title;
  final String author;
  final int? year;
  final int? rating;
  final String notes;

  Book copyWith({
    String? title,
    String? author,
    int? year,
    bool clearYear = false,
    int? rating,
    bool clearRating = false,
    String? notes,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      year: clearYear ? null : (year ?? this.year),
      rating: clearRating ? null : (rating ?? this.rating),
      notes: notes ?? this.notes,
    );
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      year: json['year'] as int?,
      rating: json['rating'] as int?,
      notes: (json['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'year': year,
      'rating': rating,
      'notes': notes,
    };
  }
}
