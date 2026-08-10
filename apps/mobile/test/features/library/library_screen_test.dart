import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readme_ai/features/auth/domain/auth_user.dart';
import 'package:readme_ai/features/library/application/library_controller.dart';
import 'package:readme_ai/features/library/domain/book.dart';
import 'package:readme_ai/features/library/domain/book_status.dart';
import 'package:readme_ai/features/library/presentation/book_detail_screen.dart';
import 'package:readme_ai/features/library/presentation/library_screen.dart';
import 'package:readme_ai/features/library/presentation/widgets/book_card.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_file_picker.dart';
import '../../helpers/fake_library_repository.dart';
import '../../helpers/pump_app.dart';

const _signedIn = AuthUser(uid: 'u1', email: 'a@b.com');

Book _book({
  String id = 'b1',
  String title = 'Clean Architecture',
  BookStatus status = BookStatus.ready,
}) => Book(
  id: id,
  title: title,
  originalFilename: '$title.pdf',
  mimeType: 'application/pdf',
  fileSize: 2048,
  status: status,
  uploadedAt: DateTime(2026),
);

void main() {
  testWidgets('renders the user\'s books', (tester) async {
    final auth = FakeAuthRepository(initialUser: _signedIn);
    addTearDown(auth.dispose);
    final library = FakeLibraryRepository(initial: [_book()]);

    await pumpApp(tester, authRepository: auth, libraryRepository: library);

    expect(find.byType(BookCard), findsOneWidget);
    expect(find.text('Clean Architecture'), findsWidgets);
  });

  testWidgets('offers the most recent readable book for resuming', (
    tester,
  ) async {
    final auth = FakeAuthRepository(initialUser: _signedIn);
    addTearDown(auth.dispose);
    final library = FakeLibraryRepository(
      initial: [
        _book(id: 'b1', title: 'Dune'),
        _book(id: 'b2', title: 'Ubik'),
      ],
    );

    await pumpApp(tester, authRepository: auth, libraryRepository: library);

    // The resume card leads, and names the first readable book.
    expect(find.text('START READING'), findsOneWidget);
    expect(find.text('Dune'), findsWidgets);
    expect(find.text('All books'), findsOneWidget);
  });

  testWidgets('shows the empty state with format guidance', (tester) async {
    final auth = FakeAuthRepository(initialUser: _signedIn);
    addTearDown(auth.dispose);

    await pumpApp(
      tester,
      authRepository: auth,
      libraryRepository: FakeLibraryRepository(),
    );

    expect(find.text('Your library is empty'), findsOneWidget);
    expect(
      find.textContaining('Text files read straight away'),
      findsOneWidget,
    );
    expect(find.byType(BookCard), findsNothing);
  });

  testWidgets('shows a skeleton while the library loads', (tester) async {
    final auth = FakeAuthRepository(initialUser: _signedIn);
    addTearDown(auth.dispose);
    final library = FakeLibraryRepository()..releaseList = Completer<void>();

    await pumpApp(
      tester,
      authRepository: auth,
      libraryRepository: library,
      settle: false,
    );
    // Let the auth stream resolve and the router settle on the library; the
    // book list request is still pending.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('library-skeleton')), findsOneWidget);

    library.releaseList!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Your library is empty'), findsOneWidget);
  });

  testWidgets('shows an error state with retry on failure', (tester) async {
    final auth = FakeAuthRepository(initialUser: _signedIn);
    addTearDown(auth.dispose);
    final library = FakeLibraryRepository()..listError = Exception('boom');

    await pumpApp(tester, authRepository: auth, libraryRepository: library);

    expect(find.text("Couldn't load your library."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('uploading a book adds it to the library', (tester) async {
    final auth = FakeAuthRepository(initialUser: _signedIn);
    addTearDown(auth.dispose);
    final library = FakeLibraryRepository();
    final picker = FakeFilePicker(result: FakeFilePicker.sampleBook());

    await pumpApp(
      tester,
      authRepository: auth,
      libraryRepository: library,
      filePicker: picker,
    );
    expect(find.byType(BookCard), findsNothing);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Upload book'));
    await tester.pumpAndSettle();

    expect(find.byType(BookCard), findsOneWidget);
  });

  testWidgets('a book still being prepared says so and then becomes ready', (
    tester,
  ) async {
    final auth = FakeAuthRepository(initialUser: _signedIn);
    addTearDown(auth.dispose);
    final library = FakeLibraryRepository(
      initial: [_book(status: BookStatus.processing)],
    );

    await pumpApp(tester, authRepository: auth, libraryRepository: library);

    expect(find.text('Preparing'), findsOneWidget);
    expect(find.textContaining('Getting this book ready'), findsOneWidget);
    final callsBefore = library.listCalls;

    // The backend finishes; the library discovers it by polling, with no
    // pull-to-refresh from the reader.
    library
      ..reset(initial: [_book()])
      ..listCalls = callsBefore;
    await tester.pump(LibraryController.pollInterval);
    await tester.pumpAndSettle();

    expect(library.listCalls, greaterThan(callsBefore));
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('a failed book offers Try again', (tester) async {
    final auth = FakeAuthRepository(initialUser: _signedIn);
    addTearDown(auth.dispose);
    final library = FakeLibraryRepository(
      initial: [_book(status: BookStatus.failed)],
    );

    await pumpApp(tester, authRepository: auth, libraryRepository: library);

    expect(find.text('Failed'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(library.retryProcessingCalls, 1);
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('deleting a book removes it via the detail screen', (
    tester,
  ) async {
    final auth = FakeAuthRepository(initialUser: _signedIn);
    addTearDown(auth.dispose);
    final library = FakeLibraryRepository(initial: [_book()]);

    await pumpApp(tester, authRepository: auth, libraryRepository: library);

    // Open the detail screen.
    await tester.tap(find.byType(BookCard));
    await tester.pumpAndSettle();
    expect(find.byType(BookDetailScreen), findsOneWidget);

    // Trigger and confirm the delete dialog.
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    // Back on the library, now empty.
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(find.byType(BookCard), findsNothing);
    expect(find.text('Your library is empty'), findsOneWidget);
  });
}
