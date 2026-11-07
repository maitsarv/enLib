import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_app/main.dart';
import 'package:book_app/models/book.dart';
import 'package:book_app/services/book_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('BookRepository saves and loads books with authors', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = BookRepository(prefs);
    expect(repository.loadBooks(), isEmpty);
    expect(repository.loadAuthors(), isEmpty);

    final author = await repository.addAuthor('J. R. R. Tolkien');
    final book = Book(
      id: '1',
      title: 'The Hobbit',
      authorId: author.id,
      isbn: '978-0261102217',
      year: 1937,
      notes: 'Great adventure.',
    );
    await repository.saveBooks([book]);

    final reloaded = BookRepository(await SharedPreferences.getInstance());
    final loaded = reloaded.loadBooks();
    expect(loaded, hasLength(1));
    expect(loaded.first.title, 'The Hobbit');
    expect(loaded.first.authorId, author.id);
    expect(loaded.first.isbn, '978-0261102217');
    expect(loaded.first.year, 1937);
    expect(loaded.first.notes, 'Great adventure.');
    expect(reloaded.loadAuthors().first.name, 'J. R. R. Tolkien');
  });

  test('addAuthor reuses an existing author with the same name', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = BookRepository(prefs);
    final first = await repository.addAuthor('Frank Herbert');
    final second = await repository.addAuthor('Frank Herbert');
    expect(second.id, first.id);
    expect(repository.loadAuthors(), hasLength(1));
  });

  testWidgets('empty state is shown when no books exist', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(const BookApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('No books yet'), findsOneWidget);
    expect(find.text('Add Book'), findsOneWidget);
  });

  testWidgets('user can add a book with a new author via the form',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(const BookApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Book'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'The Pragmatic Programmer',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Author name'),
      'Andrew Hunt',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ISBN (optional)'),
      '9780201616224',
    );
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text('The Pragmatic Programmer'), findsOneWidget);
    expect(find.text('Andrew Hunt'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final repository = BookRepository(prefs);
    final books = repository.loadBooks();
    final authors = repository.loadAuthors();
    expect(books, hasLength(1));
    expect(authors, hasLength(1));
    expect(authors.first.name, 'Andrew Hunt');
    expect(books.first.authorId, authors.first.id);
    expect(books.first.isbn, '9780201616224');
  });

  testWidgets('user can pick an existing author from the dropdown',
      (tester) async {
    _useTallSurface(tester);
    final prefs = await SharedPreferences.getInstance();
    final repository = BookRepository(prefs);
    final author = await repository.addAuthor('Frank Herbert');

    await tester.pumpWidget(const BookApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Book'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Dune',
    );
    await tester.tap(find.text('Author'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frank Herbert').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    final books = BookRepository(await SharedPreferences.getInstance())
        .loadBooks();
    expect(books, hasLength(1));
    expect(books.first.authorId, author.id);
    expect(find.text('Dune'), findsOneWidget);
  });

  testWidgets('form validation blocks empty and invalid fields',
      (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(const BookApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Book'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'ISBN (optional)'),
      '123',
    );
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a title'), findsOneWidget);
    expect(find.text('Please enter an author name'), findsOneWidget);
    expect(find.text('ISBN must be 10 or 13 characters'), findsOneWidget);
  });

  testWidgets('user can open details and edit a book', (tester) async {
    _useTallSurface(tester);
    final prefs = await SharedPreferences.getInstance();
    final repository = BookRepository(prefs);
    final author = await repository.addAuthor('Frank Herbert');
    await repository.saveBooks([
      Book(
        id: '1',
        title: 'Dune',
        authorId: author.id,
        isbn: '9780441013593',
      ),
    ]);

    await tester.pumpWidget(const BookApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dune'));
    await tester.pumpAndSettle();
    expect(find.text('by Frank Herbert'), findsOneWidget);
    expect(find.text('9780441013593'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Dune Messiah',
    );
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();
    await tester.pumpAndSettle();

    final books = BookRepository(await SharedPreferences.getInstance())
        .loadBooks();
    expect(books, hasLength(1));
    expect(books.first.title, 'Dune Messiah');
    expect(books.first.isbn, '9780441013593');
  });
}
