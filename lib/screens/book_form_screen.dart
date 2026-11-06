import 'package:flutter/material.dart';

import '../models/author.dart';
import '../models/book.dart';

class BookFormResult {
  const BookFormResult({required this.book, this.author});

  final Book book;

  final Author? author;
}

class BookFormScreen extends StatefulWidget {
  const BookFormScreen({
    super.key,
    required this.authors,
    this.book,
  });

  final Book? book;
  final List<Author> authors;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _isbnController;
  late final TextEditingController _yearController;
  late final TextEditingController _notesController;
  late final TextEditingController _newAuthorController;
  String? _selectedAuthorId;
  bool _creatingNewAuthor = false;

  static const _newAuthorOption = '__new_author__';

  bool get _isEditing => widget.book != null;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _titleController = TextEditingController(text: book?.title ?? '');
    _isbnController = TextEditingController(text: book?.isbn ?? '');
    _yearController =
        TextEditingController(text: book?.year?.toString() ?? '');
    _notesController = TextEditingController(text: book?.notes ?? '');
    _newAuthorController = TextEditingController();
    _selectedAuthorId = book?.authorId;
    if (_selectedAuthorId != null &&
        !widget.authors.any((a) => a.id == _selectedAuthorId)) {
      _creatingNewAuthor = true;
    }
    if (widget.authors.isEmpty) {
      _creatingNewAuthor = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    _notesController.dispose();
    _newAuthorController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final yearText = _yearController.text.trim();
    Author? newAuthor;
    String authorId;
    if (_creatingNewAuthor) {
      newAuthor = Author(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _newAuthorController.text.trim(),
      );
      authorId = newAuthor.id;
    } else {
      authorId = _selectedAuthorId!;
    }
    Navigator.of(context).pop(
      BookFormResult(
        book: Book(
          id: widget.book?.id ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          authorId: authorId,
          isbn: _isbnController.text.trim(),
          year: yearText.isEmpty ? null : int.parse(yearText),
          notes: _notesController.text.trim(),
        ),
        author: newAuthor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Book' : 'Add Book'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (_creatingNewAuthor)
              TextFormField(
                controller: _newAuthorController,
                decoration: InputDecoration(
                  labelText: 'Author name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: widget.authors.isEmpty
                        ? null
                        : () => setState(() {
                              _creatingNewAuthor = false;
                              _selectedAuthorId = widget.authors.first.id;
                            }),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an author name';
                  }
                  return null;
                },
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedAuthorId,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: [
                  for (final author in widget.authors)
                    DropdownMenuItem(
                      value: author.id,
                      child: Text(author.name),
                    ),
                  DropdownMenuItem(
                    value: _newAuthorOption,
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 8),
                        Text('New author...'),
                      ],
                    ),
                  ),
                ],
                validator: (value) {
                  if (value == null) {
                    return 'Please select an author';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value == _newAuthorOption) {
                    setState(() => _creatingNewAuthor = true);
                  } else {
                    setState(() => _selectedAuthorId = value);
                  }
                },
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isbnController,
              decoration: const InputDecoration(
                labelText: 'ISBN (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.barcode_reader),
              ),
              keyboardType: TextInputType.text,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return null;
                }
                final cleaned = text.replaceAll('-', '');
                if (cleaned.length == 10 || cleaned.length == 13) {
                  return null;
                }
                return 'ISBN must be 10 or 13 characters';
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year published (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null;
                }
                final year = int.tryParse(value.trim());
                if (year == null) {
                  return 'Enter a valid year';
                }
                if (year < 1000 || year > 2100) {
                  return 'Enter a year between 1000 and 2100';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Save Changes' : 'Add Book'),
            ),
          ],
        ),
      ),
    );
  }
}
