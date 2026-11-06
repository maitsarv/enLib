import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _repository = BookRepository(prefs);
        _books = _repository!.loadBooks();
      });
    });
  }

  Future<void> _addBook(Book book) async {
    await _repository!.saveBooks([..._books, book]);
    setState(() => _books = _repository!.loadBooks());
  }

  Future<void> _updateBook(Book book) async {
    await _repository!.saveBooks([
      for (final existing in _books)
        existing.id == book.id ? book : existing,
    ]);
    setState(() => _books = _repository!.loadBooks());
  }

  Future<void> _deleteBook(Book book) async {
    await _repository!.saveBooks([
      for (final existing in _books)
        if (existing.id != book.id) existing,
    ]);
    setState(() => _books = _repository!.loadBooks());
  }

  Future<void> _openForm({Book? book}) async {
    final result = await Navigator.of(context).push<Book>(
      MaterialPageRoute(builder: (context) => BookFormScreen(book: book)),
    );
    if (result == null) return;
    if (book == null) {
      await _addBook(result);
    } else {
      await _updateBook(result);
    }
  }

  Future<void> _openDetails(Book book) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(bookId: book.id),
      ),
    );
    if (changed == true) {
      setState(() => _books = _repository!.loadBooks());
    }
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
                    subtitle: Text(book.author),
                    trailing: book.rating == null
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (i) {
                              return Icon(
                                i < book.rating!
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color: Colors.amber,
                              );
                            }),
                          ),
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
