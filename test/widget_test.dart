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

  test('BookRepository saves and loads books', () async {
    final prefs = await SharedPreferences.getInstance();
    final repository = BookRepository(prefs);
    expect(repository.loadBooks(), isEmpty);

    final book = Book(
      id: '1',
      title: 'The Hobbit',
      author: 'J. R. R. Tolkien',
      year: 1937,
      rating: 5,
      notes: 'Great adventure.',
    );
    await repository.saveBooks([book]);

    final loaded = repository.loadBooks();
    expect(loaded, hasLength(1));
    expect(loaded.first.title, 'The Hobbit');
    expect(loaded.first.author, 'J. R. R. Tolkien');
    expect(loaded.first.year, 1937);
    expect(loaded.first.rating, 5);
    expect(loaded.first.notes, 'Great adventure.');
  });

  test('BookRepository persists across instances', () async {
    final prefs = await SharedPreferences.getInstance();
    await BookRepository(prefs).saveBooks([
      const Book(id: '1', title: 'Dune', author: 'Frank Herbert'),
    ]);

    final repository = BookRepository(await SharedPreferences.getInstance());
    expect(repository.loadBooks().first.title, 'Dune');
  });

  testWidgets('empty state is shown when no books exist', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(const BookApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('No books yet'), findsOneWidget);
    expect(find.text('Add Book'), findsOneWidget);
  });

  testWidgets('user can add a book via the form', (tester) async {
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
      find.widgetWithText(TextFormField, 'Author'),
      'Andrew Hunt',
    );
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text('The Pragmatic Programmer'), findsOneWidget);
    expect(find.text('Andrew Hunt'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final books = BookRepository(prefs).loadBooks();
    expect(books, hasLength(1));
    expect(books.first.title, 'The Pragmatic Programmer');
    expect(books.first.author, 'Andrew Hunt');
  });

  testWidgets('form validation blocks empty fields', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(const BookApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Book'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a title'), findsOneWidget);
    expect(find.text('Please enter an author'), findsOneWidget);
  });

  testWidgets('user can open details and edit a book', (tester) async {
    _useTallSurface(tester);
    final prefs = await SharedPreferences.getInstance();
    await BookRepository(prefs).saveBooks([
      const Book(id: '1', title: 'Dune', author: 'Frank Herbert'),
    ]);

    await tester.pumpWidget(const BookApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dune'));
    await tester.pumpAndSettle();
    expect(find.text('by Frank Herbert'), findsOneWidget);

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
    expect(books.first.author, 'Frank Herbert');
  });
}
