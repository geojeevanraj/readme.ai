import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readme_ai/core/files/file_picker_service.dart';
import 'package:readme_ai/core/state/retry_policy.dart';
import 'package:readme_ai/features/library/application/library_controller.dart';
import 'package:readme_ai/features/library/application/library_providers.dart';
import 'package:readme_ai/features/library/application/upload_controller.dart';
import 'package:readme_ai/features/library/domain/book.dart';
import 'package:readme_ai/features/library/domain/book_status.dart';

import '../../helpers/fake_file_picker.dart';
import '../../helpers/fake_library_repository.dart';

Book _book(String id, {BookStatus status = BookStatus.ready}) => Book(
  id: id,
  title: 'Book $id',
  originalFilename: '$id.pdf',
  mimeType: 'application/pdf',
  fileSize: 1024,
  status: status,
  uploadedAt: DateTime(2026),
);

ProviderContainer _container(
  FakeLibraryRepository repository, {
  FilePickerService? picker,
}) {
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: [
      libraryRepositoryProvider.overrideWithValue(repository),
      if (picker != null) filePickerProvider.overrideWithValue(picker),
    ],
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

  test('uploading reports progress and refreshes the list', () async {
    final repository = FakeLibraryRepository();
    final container = _container(
      repository,
      picker: FakeFilePicker(result: FakeFilePicker.sampleBook()),
    );
    await container.read(libraryControllerProvider.future);

    final picked = await container
        .read(uploadControllerProvider.notifier)
        .pickAndUpload();

    expect(picked, isTrue);
    expect(repository.reportedProgress, [0.5, 1]);
    // The job clears once the book is in the library.
    expect(container.read(uploadControllerProvider), isNull);
    expect(
      container.read(libraryControllerProvider).requireValue,
      hasLength(1),
    );
  });

  test('a failed upload keeps the file so it can be retried', () async {
    final repository = FakeLibraryRepository()..uploadError = Exception('boom');
    final container = _container(
      repository,
      picker: FakeFilePicker(result: FakeFilePicker.sampleBook()),
    );
    await container.read(libraryControllerProvider.future);

    await container.read(uploadControllerProvider.notifier).pickAndUpload();

    final job = container.read(uploadControllerProvider);
    expect(job, isNotNull);
    expect(job!.failed, isTrue);

    // Retry succeeds without touching the file picker again.
    repository.uploadError = null;
    await container.read(uploadControllerProvider.notifier).retry();

    expect(container.read(uploadControllerProvider), isNull);
    expect(
      container.read(libraryControllerProvider).requireValue,
      hasLength(1),
    );
  });

  test('retryProcessing re-runs preparation and refreshes', () async {
    final repository = FakeLibraryRepository(
      initial: [_book('1', status: BookStatus.failed)],
    );
    final container = _container(repository);
    await container.read(libraryControllerProvider.future);

    await container
        .read(libraryControllerProvider.notifier)
        .retryProcessing('1');

    expect(repository.retryProcessingCalls, 1);
    expect(
      container.read(libraryControllerProvider).requireValue.single.status,
      BookStatus.ready,
    );
  });

  test('continueReading picks the most recent readable book', () async {
    final container = _container(
      FakeLibraryRepository(
        initial: [
          _book('1', status: BookStatus.processing),
          _book('2'),
          _book('3'),
        ],
      ),
    );
    await container.read(libraryControllerProvider.future);

    expect(container.read(continueReadingProvider)?.id, '2');
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
