import 'dart:async';

import 'package:readme_ai/core/files/picked_book.dart';
import 'package:readme_ai/features/library/domain/book.dart';
import 'package:readme_ai/features/library/domain/book_status.dart';
import 'package:readme_ai/features/library/domain/library_repository.dart';

/// In-memory [LibraryRepository] for widget and unit tests.
class FakeLibraryRepository implements LibraryRepository {
  FakeLibraryRepository({List<Book>? initial}) : _books = [...?initial];

  final List<Book> _books;

  /// When set, [listBooks] throws this.
  Object? listError;

  /// When set, [uploadBook] throws this.
  Object? uploadError;

  /// When set, [listBooks] awaits this before returning (to test loading).
  Completer<void>? releaseList;

  int listCalls = 0;

  @override
  Future<List<Book>> listBooks() async {
    listCalls++;
    if (releaseList != null) {
      await releaseList!.future;
    }
    if (listError != null) {
      throw listError!;
    }
    return List.of(_books);
  }

  @override
  Future<Book> getBook(String id) async =>
      _books.firstWhere((book) => book.id == id);

  @override
  Future<Book> uploadBook(PickedBook file) async {
    if (uploadError != null) {
      throw uploadError!;
    }
    final book = Book(
      id: 'id-${_books.length + 1}',
      title: file.filename,
      originalFilename: file.filename,
      mimeType: file.mimeType ?? 'application/pdf',
      fileSize: file.size,
      status: BookStatus.uploaded,
      uploadedAt: DateTime(2026),
    );
    _books.insert(0, book);
    return book;
  }

  @override
  Future<void> deleteBook(String id) async {
    _books.removeWhere((book) => book.id == id);
  }
}
