# ReadMe.ai — Mobile (Flutter client)

The Flutter reading client for ReadMe.ai. **Sprint 3.0** adds the reader: a
distraction-free reflowable text reader with adjustable typography, light/dark
mode, persistent reading position, and bookmarks.

## Firebase setup (required to actually sign in)

Configuration is supplied at build time via `--dart-define` (no
`firebase_options.dart` is committed, so no credentials live in the repo).
Obtain these values from your Firebase project and Google OAuth setup:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=... \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=...   # for Google Sign-In token exchange
```

Platform OAuth setup (Android SHA keys, iOS URL schemes, web client id) is also
required per the Firebase/Google Sign-In docs. Without configuration the app
still launches to the login screen; sign-in then reports missing configuration.

A `--dart-define-from-file=env.json` is recommended for day-to-day development.

## Auth feature structure (feature-first)

```
lib/features/auth/
├── domain/        # AuthUser, AuthRepository (interface), AuthException
├── data/          # FirebaseAuthRepository (Firebase + Google Sign-In)
├── application/   # auth_providers (DI + state stream), auth_controller
└── presentation/  # splash_page, login_page
```

The `AuthRepository` interface hides Firebase from the application/presentation
layers; the router (`core/router`) enforces protected navigation by listening to
the auth state stream.

## Library feature structure

```
lib/features/library/
├── domain/        # Book, BookStatus, LibraryRepository (interface)
├── data/          # BookDto (JSON) + LibraryRepositoryImpl (Dio)
├── application/   # library_providers, library_controller (list/upload/delete)
└── presentation/  # library_screen, book_detail_screen, widgets/book_card
```

The authenticated landing route (`/home`) is the library; book detail is a
nested route (`/home/books/:bookId`). File selection is abstracted behind
`core/files/FilePickerService` so the upload flow is testable without the native
picker.

## Reader feature structure

```
lib/features/reader/
├── domain/        # BookContent, ContentFormat, ReadingProgress, Bookmark, repo
├── data/          # DTOs (JSON) + ReaderRepositoryImpl (Dio)
├── application/   # reader_providers (family futures), ReaderController,
│                  # ReaderSettings(+controller)
└── presentation/  # reader_screen + widgets (settings sheet, bookmarks sheet)
```

The reader (`/home/books/:bookId/read`) renders reflowable text with adjustable
font size / line spacing and light/dark mode. Reading position and bookmarks use
**stable character-offset anchors** (not page numbers). Non-text formats (PDF)
show a documented "preview not available yet" message pending a future parser.

## Commands

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build              # Freezed / json_serializable codegen
flutter run --dart-define=...            # see Firebase setup above

# quality gates
dart format --set-exit-if-changed . && flutter analyze && flutter test
```

> Generated files (`*.g.dart`, `*.freezed.dart`, `lib/l10n/generated/`) are not
> committed; run `build_runner` and `flutter gen-l10n` after checkout.
