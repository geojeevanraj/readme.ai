import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readme_ai/features/library/application/library_controller.dart';
import 'package:readme_ai/features/library/application/library_providers.dart';
import 'package:readme_ai/features/library/domain/book.dart';
import 'package:readme_ai/features/library/domain/book_status.dart';

import '../../helpers/fake_file_picker.dart';
import '../../helpers/fake_library_repository.dart';

Book _book(String id) => Book(
  id: id,
  title: 'Book $id',
  originalFilename: '$id.pdf',
  mimeType: 'application/pdf',
  fileSize: 1024,
  status: BookStatus.uploaded,
  uploadedAt: DateTime(2026),
);

ProviderContainer _container(FakeLibraryRepository repository) {
  final container = ProviderContainer(
    overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('build loads the user\'s books', () async {
    final container = _container(FakeLibraryRepository(initial: [_book('1')]));

    final books = await container.read(libraryControllerProvider.future);

    expect(books, hasLength(1));
  });

  test('uploadBook refreshes the list with the new book', () async {
    final repository = FakeLibraryRepository();
    final container = _container(repository);
    await container.read(libraryControllerProvider.future);

    await container
        .read(libraryControllerProvider.notifier)
        .uploadBook(FakeFilePicker.sampleBook());

    expect(
      container.read(libraryControllerProvider).requireValue,
      hasLength(1),
    );
  });

  test('deleteBook removes the book from the list', () async {
    final repository = FakeLibraryRepository(initial: [_book('1'), _book('2')]);
    final container = _container(repository);
    await container.read(libraryControllerProvider.future);

    await container.read(libraryControllerProvider.notifier).deleteBook('1');

    final remaining = container.read(libraryControllerProvider).requireValue;
    expect(remaining.map((book) => book.id), ['2']);
  });
}
