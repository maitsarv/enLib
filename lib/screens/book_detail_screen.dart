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

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final repository = BookRepository(prefs);
      setState(() {
        _book = repository.loadBooks().firstWhere(
              (book) => book.id == widget.bookId,
              orElse: () => throw StateError('Book not found'),
            );
      });
    });
  }

  Future<void> _edit() async {
    final book = _book;
    if (book == null) return;
    final result = await Navigator.of(context).push<Book>(
      MaterialPageRoute(builder: (context) => BookFormScreen(book: book)),
    );
    if (result == null) return;
    final prefs = await SharedPreferences.getInstance();
    final repository = BookRepository(prefs);
    final books = repository.loadBooks();
    await repository.saveBooks([
      for (final existing in books)
        existing.id == result.id ? result : existing,
    ]);
    setState(() => _book = result);
    if (mounted) Navigator.of(context).pop(true);
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
          Text('by ${book.author}', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          if (book.rating != null)
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < book.rating! ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                );
              }),
            ),
          if (book.rating != null) const SizedBox(height: 16),
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
