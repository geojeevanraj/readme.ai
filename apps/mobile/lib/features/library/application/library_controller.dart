import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/book.dart';
import '../domain/library_repository.dart';
import 'library_providers.dart';

/// Owns the library list state, the delete action, and processing retries.
///
/// A freshly uploaded book arrives as `PROCESSING` and becomes `READY` some
/// seconds later. The API has no push channel, so the controller polls while
/// any book is still being prepared and stops as soon as none are — the reader
/// never has to pull-to-refresh to discover that their book is ready.
class LibraryController extends AsyncNotifier<List<Book>> {
  /// How often to re-check books that are still being prepared.
  static const Duration pollInterval = Duration(seconds: 4);

  Timer? _poll;

  LibraryRepository get _repository => ref.read(libraryRepositoryProvider);

  @override
  Future<List<Book>> build() async {
    ref.onDispose(() => _poll?.cancel());
    final books = await _repository.listBooks();
    _schedulePoll(books);
    return books;
  }

  /// Re-fetch the library. The list stays visible while the request is in
  /// flight, so a refresh never blanks the screen.
  Future<void> refresh() async {
    final next = await AsyncValue.guard(_repository.listBooks);
    state = next;
    _schedulePoll(next.value ?? const []);
  }

  /// Ask the backend to process [id] again after a failure.
  Future<void> retryProcessing(String id) async {
    await _repository.retryProcessing(id);
    await refresh();
  }

  /// Delete a book and remove it from the list. Rethrows on failure.
  Future<void> deleteBook(String id) async {
    await _repository.deleteBook(id);
    final current = state.value ?? const [];
    state = AsyncData([
      for (final book in current)
        if (book.id != id) book,
    ]);
  }

  void _schedulePoll(List<Book> books) {
    _poll?.cancel();
    if (!books.any((book) => book.status.isTransient)) return;
    _poll = Timer(pollInterval, refresh);
  }
}

/// Exposes the [LibraryController] and the current library list.
final libraryControllerProvider =
    AsyncNotifierProvider<LibraryController, List<Book>>(LibraryController.new);

/// The book to offer as "continue reading": the most recently uploaded book
/// that can actually be read.
///
/// The list endpoint carries no last-opened timestamp and no per-book progress,
/// so "most recent readable" is the best available proxy. Ordering by genuine
/// last-read time needs a backend field.
final continueReadingProvider = Provider<Book?>((ref) {
  final books = ref.watch(libraryControllerProvider).value ?? const [];
  for (final book in books) {
    if (book.status.isReadable) return book;
  }
  return null;
});
