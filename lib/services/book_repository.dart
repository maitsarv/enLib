import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/author.dart';
import '../models/book.dart';

class BookRepository {
  BookRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _booksKey = 'books';
  static const _authorsKey = 'authors';

  List<Book> loadBooks() {
    final raw = _prefs.getString(_booksKey);
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
      _booksKey,
      jsonEncode(books.map((book) => book.toJson()).toList()),
    );
  }

  List<Author> loadAuthors() {
    final raw = _prefs.getString(_authorsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Author.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAuthors(List<Author> authors) async {
    await _prefs.setString(
      _authorsKey,
      jsonEncode(authors.map((author) => author.toJson()).toList()),
    );
  }

  Future<Author> addAuthor(String name) async {
    final authors = loadAuthors();
    final existing = authors.where((a) => a.name == name).firstOrNull;
    if (existing != null) {
      return existing;
    }
    final author = Author(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
    );
    await saveAuthors([...authors, author]);
    return author;
  }

  Future<void> saveAuthor(Author author) async {
    final authors = loadAuthors();
    if (authors.any((a) => a.id == author.id)) {
      return;
    }
    await saveAuthors([...authors, author]);
  }

  Future<void> migrate() async {
    final authors = loadAuthors();
    final books = loadBooks();
    var changed = false;

    final migratedAuthors = [...authors];
    final migratedBooks = <Book>[];
    for (final book in books) {
      if (book.authorId.isNotEmpty) {
        migratedBooks.add(book);
        continue;
      }
      final legacyName = _legacyAuthorName(book.id);
      if (legacyName == null || legacyName.isEmpty) {
        migratedBooks.add(book);
        continue;
      }
      var author = migratedAuthors
          .where((a) => a.name == legacyName)
          .firstOrNull;
      if (author == null) {
        author = Author(
          id: '${book.id}-author',
          name: legacyName,
        );
        migratedAuthors.add(author);
      }
      migratedBooks.add(book.copyWith(authorId: author.id));
      changed = true;
    }

    if (changed) {
      await saveAuthors(migratedAuthors);
      await saveBooks(migratedBooks);
    }
  }

  String? _legacyAuthorName(String bookId) {
    final raw = _prefs.getString(_booksKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    for (final item in decoded) {
      final map = item as Map<String, dynamic>;
      if (map['id'] == bookId) {
        return map['author'] as String?;
      }
    }
    return null;
  }
}
