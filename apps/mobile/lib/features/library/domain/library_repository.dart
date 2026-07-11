import '../../../core/files/picked_book.dart';
import 'book.dart';

/// Contract for the user's book library.
///
/// The presentation/application layers depend on this interface; the Dio-backed
/// implementation lives in the data layer and is injected via Riverpod so a
/// fake can be used in tests.
abstract interface class LibraryRepository {
  /// Fetch all books belonging to the current user, newest first.
  Future<List<Book>> listBooks();

  /// Fetch a single book by id.
  Future<Book> getBook(String id);

  /// Upload a picked file and return the created book.
  Future<Book> uploadBook(PickedBook file);

  /// Delete a book by id.
  Future<void> deleteBook(String id);
}
