import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/reader_repository_impl.dart';
import '../domain/book_content.dart';
import '../domain/bookmark.dart';
import '../domain/reader_repository.dart';
import '../domain/reading_progress.dart';

/// Provides the [ReaderRepository]. Overridden in tests with a fake.
final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  return ReaderRepositoryImpl(ref.watch(dioProvider));
});

/// Loads a book's readable content (cached per book).
final bookContentProvider = FutureProvider.family<BookContent, String>((
  ref,
  bookId,
) {
  return ref.watch(readerRepositoryProvider).getContent(bookId);
});

/// Loads the saved reading position for resume (null if unstarted).
final readingProgressProvider = FutureProvider.family<ReadingProgress?, String>(
  (ref, bookId) {
    return ref.watch(readerRepositoryProvider).getProgress(bookId);
  },
);

/// Loads the book's bookmarks; invalidated by the controller on change.
final bookmarksProvider = FutureProvider.family<List<Bookmark>, String>((
  ref,
  bookId,
) {
  return ref.watch(readerRepositoryProvider).listBookmarks(bookId);
});
