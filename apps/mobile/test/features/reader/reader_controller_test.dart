import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readme_ai/features/reader/application/reader_controller.dart';
import 'package:readme_ai/features/reader/application/reader_providers.dart';
import 'package:readme_ai/features/reader/domain/reading_progress.dart';

import '../../helpers/fake_reader_repository.dart';

ProviderContainer _container(FakeReaderRepository repository) {
  final container = ProviderContainer(
    overrides: [readerRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('resume loads saved progress', () async {
    final repository = FakeReaderRepository(
      progress: const ReadingProgress(
        currentPosition: '120',
        progressPercentage: 40,
        totalReadingTimeSeconds: 60,
      ),
    );
    final container = _container(repository);

    final progress = await container.read(readingProgressProvider('b1').future);

    expect(progress?.currentPosition, '120');
    expect(progress?.progressPercentage, 40);
  });

  test('saveProgress persists the position', () async {
    final repository = FakeReaderRepository();
    final container = _container(repository);

    await container
        .read(readerControllerProvider)
        .saveProgress(
          'b1',
          currentPosition: '500',
          progressPercentage: 75,
          readingTimeSeconds: 45,
        );

    expect(repository.lastSaved?.currentPosition, '500');
    expect(repository.lastSaved?.progressPercentage, 75);
  });

  test('addBookmark creates and refreshes the bookmark list', () async {
    final repository = FakeReaderRepository();
    final container = _container(repository);
    expect(await container.read(bookmarksProvider('b1').future), isEmpty);

    await container
        .read(readerControllerProvider)
        .addBookmark('b1', anchor: '250');

    final bookmarks = await container.read(bookmarksProvider('b1').future);
    expect(bookmarks, hasLength(1));
    expect(bookmarks.first.anchor, '250');
  });

  test('deleteBookmark removes the bookmark', () async {
    final repository = FakeReaderRepository();
    final container = _container(repository);
    await container
        .read(readerControllerProvider)
        .addBookmark('b1', anchor: '250');
    final created = await container.read(bookmarksProvider('b1').future);

    await container
        .read(readerControllerProvider)
        .deleteBookmark('b1', created.first.id);

    expect(await container.read(bookmarksProvider('b1').future), isEmpty);
  });
}
