# My Books

A simple Flutter app for Android and iOS that stores a personal book list on the device.

## Features

- **Book list** — all saved books with title and author; swipe a row left-to-right to delete
- **Add form** — title (required), author (required, picked from existing author records or created on the fly), ISBN (10 or 13 characters), publication year, notes
- **Detail view** — full book information (author, ISBN, year, notes) with edit and delete actions
- **Local persistence** — books and authors are stored as JSON in `SharedPreferences`, no backend required
- **Migration** — books saved by older versions (author stored as plain text) are automatically converted to author records

## Project structure

```
lib/
  main.dart                    # App entry point and book list screen
  models/book.dart             # Book model with JSON serialization
  models/author.dart           # Author model (books reference authors by id)
  services/book_repository.dart# SharedPreferences-backed storage + migration
  screens/book_form_screen.dart# Add/edit form with validation
  screens/book_detail_screen.dart # Detail view with edit/delete
test/
  widget_test.dart             # Unit and widget tests
```

## Running

```bash
flutter pub get
flutter run          # with an Android device/emulator or iOS simulator attached
flutter test         # run the test suite
```

## Building release binaries

```bash
flutter build apk --release        # Android
flutter build ipa --release        # iOS (requires macOS with Xcode)
```
