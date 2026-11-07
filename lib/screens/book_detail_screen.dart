import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import '../services/book_repository.dart';
import 'book_form_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _book;
  String _authorName = 'Unknown author';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final repository = BookRepository(prefs);
    final books = repository.loadBooks();
    final book = books.where((b) => b.id == widget.bookId).firstOrNull;
    if (book == null) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    final author = repository
        .loadAuthors()
        .where((a) => a.id == book.authorId)
        .firstOrNull;
    setState(() {
      _book = book;
      _authorName = author?.name ?? 'Unknown author';
    });
  }

  Future<void> _edit() async {
    final book = _book;
    if (book == null) return;
    final prefs = await SharedPreferences.getInstance();
    final repository = BookRepository(prefs);
    if (!mounted) return;
    final result = await Navigator.of(context).push<BookFormResult>(
      MaterialPageRoute(
        builder: (context) => BookFormScreen(
          book: book,
          authors: repository.loadAuthors(),
        ),
      ),
    );
    if (result == null) return;
    if (result.author != null) {
      await repository.saveAuthor(result.author!);
    }
    final books = repository.loadBooks();
    await repository.saveBooks([
      for (final existing in books)
        existing.id == result.book.id ? result.book : existing,
    ]);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _delete() async {
    final book = _book;
    if (book == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete book'),
        content: Text('Delete "${book.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    final repository = BookRepository(prefs);
    final books = repository.loadBooks();
    await repository.saveBooks([
      for (final existing in books)
        if (existing.id != book.id) existing,
    ]);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    if (book == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(book.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('by $_authorName', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          if (book.isbn.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.barcode_reader),
              title: Text(book.isbn),
              subtitle: const Text('ISBN'),
            ),
          if (book.year != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text('Published ${book.year}'),
            ),
          if (book.notes.isNotEmpty) ...[
            Text('Notes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(book.notes, style: theme.textTheme.bodyLarge),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.edit),
        label: const Text('Edit'),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton.icon(
          onPressed: _delete,
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
