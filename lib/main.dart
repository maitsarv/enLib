import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/author.dart';
import 'models/book.dart';
import 'screens/book_detail_screen.dart';
import 'screens/book_form_screen.dart';
import 'services/book_repository.dart';

void main() {
  runApp(const BookApp());
}

class BookApp extends StatelessWidget {
  const BookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Books',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const BookListScreen(),
    );
  }
}

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  BookRepository? _repository;
  List<Book> _books = [];
  List<Author> _authors = [];

  void _reload() {
    final repository = _repository;
    if (repository == null) return;
    setState(() {
      _books = repository.loadBooks();
      _authors = repository.loadAuthors();
    });
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) async {
      final repository = BookRepository(prefs);
      await repository.migrate();
      _repository = repository;
      _reload();
    });
  }

  Future<void> _deleteBook(Book book) async {
    await _repository!.saveBooks([
      for (final existing in _books)
        if (existing.id != book.id) existing,
    ]);
    _reload();
  }

  Future<void> _openForm({Book? book}) async {
    final result = await Navigator.of(context).push<BookFormResult>(
      MaterialPageRoute(
        builder: (context) => BookFormScreen(
          book: book,
          authors: _authors,
        ),
      ),
    );
    if (result == null) return;
    if (result.author != null) {
      await _repository!.saveAuthor(result.author!);
    }
    if (book == null) {
      await _repository!.saveBooks([..._books, result.book]);
    } else {
      await _repository!.saveBooks([
        for (final existing in _books)
          existing.id == result.book.id ? result.book : existing,
      ]);
    }
    _reload();
  }

  Future<void> _openDetails(Book book) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(bookId: book.id),
      ),
    );
    if (changed == true) {
      _reload();
    }
  }

  String _authorName(Book book) {
    return _authors
            .where((author) => author.id == book.authorId)
            .firstOrNull
            ?.name ??
        'Unknown author';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Books')),
      body: _books.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No books yet.\nTap "Add Book" to add your first one.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final book = _books[index];
                return Dismissible(
                  key: ValueKey(book.id),
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (_) => _deleteBook(book),
                  child: ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(book.title),
                    subtitle: Text(_authorName(book)),
                    onTap: () => _openDetails(book),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
    );
  }
}
