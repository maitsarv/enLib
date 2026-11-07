import 'package:flutter/foundation.dart';

@immutable
class Author {
  const Author({required this.id, required this.name});

  final String id;
  final String name;

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
