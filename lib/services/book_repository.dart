import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

class BookRepository {
  BookRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _storageKey = 'books';

  List<Book> loadBooks() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Book.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveBooks(List<Book> books) async {
    await _prefs.setString(
      _storageKey,
      jsonEncode(books.map((book) => book.toJson()).toList()),
    );
  }
}
