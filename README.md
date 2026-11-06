# My Books

A simple Flutter app for Android and iOS that stores a personal book list on the device.

## Features

- **Book list** — all saved books with title, author, and star rating; swipe a row left-to-right to delete
- **Add form** — title (required), author (required), publication year, 1–5 star rating, notes
- **Detail view** — full book information with edit and delete actions
- **Local persistence** — books are stored as JSON in `SharedPreferences`, no backend required

## Project structure

```
lib/
  main.dart                    # App entry point and book list screen
  models/book.dart             # Book model with JSON serialization
  services/book_repository.dart# SharedPreferences-backed storage
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
