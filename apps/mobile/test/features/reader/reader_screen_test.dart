import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readme_ai/core/theme/theme_mode_controller.dart';
import 'package:readme_ai/features/reader/application/reader_settings_controller.dart';
import 'package:readme_ai/features/reader/domain/bookmark.dart';
import 'package:readme_ai/features/reader/domain/reading_progress.dart';
import 'package:readme_ai/features/reader/presentation/widgets/bookmarks_sheet.dart';
import 'package:readme_ai/features/reader/presentation/widgets/page_turn_view.dart';

import '../../helpers/fake_reader_repository.dart';
import '../../helpers/pump_reader.dart';

void main() {
  testWidgets('renders readable text content', (tester) async {
    await pumpReader(tester, repository: FakeReaderRepository());

    expect(find.textContaining('bright cold day in April'), findsOneWidget);
    expect(find.text('Nineteen Eighty-Four'), findsOneWidget);
  });

  testWidgets('shows a limitation message for unsupported formats', (
    tester,
  ) async {
    await pumpReader(
      tester,
      repository: FakeReaderRepository(
        content: FakeReaderRepository.unsupportedContent(),
      ),
    );

    expect(
      find.text("Preview isn't available for this file format yet."),
      findsOneWidget,
    );
  });

  testWidgets('reader settings adjust font size', (tester) async {
    final container = await pumpReader(
      tester,
      repository: FakeReaderRepository(),
    );
    final initial = container.read(readerSettingsProvider).fontSize;

    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Increase Font size'));
    await tester.pumpAndSettle();

    expect(container.read(readerSettingsProvider).fontSize, initial + 2);
  });

  testWidgets('reader settings toggle dark mode', (tester) async {
    final container = await pumpReader(
      tester,
      repository: FakeReaderRepository(),
    );

    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('turning a logical page saves its stable character anchor', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final text = List.generate(
      180,
      (index) =>
          'Concept $index builds understanding through careful reading. ',
    ).join();
    final repository = FakeReaderRepository(
      content: FakeReaderRepository.textContent(text: text),
    );

    await pumpReader(tester, repository: repository);

    expect(find.byType(PageTurnView), findsOneWidget);
    expect(find.textContaining('Page 1 of '), findsOneWidget);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Page 2 of '), findsOneWidget);
    expect(repository.lastSaved, isNotNull);
    expect(int.parse(repository.lastSaved!.currentPosition), greaterThan(0));
  });

  testWidgets('restores a nonzero scalar anchor to its logical page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final text = List.generate(
      240,
      (index) => '😀 Chapter $index preserves the reader position. ',
    ).join();
    final repository = FakeReaderRepository(
      content: FakeReaderRepository.textContent(text: text),
      progress: const ReadingProgress(
        currentPosition: '1800',
        progressPercentage: 20,
        totalReadingTimeSeconds: 0,
      ),
    );

    await pumpReader(tester, repository: repository);

    expect(find.textContaining('Page 1 of '), findsNothing);
    expect(find.textContaining('Page '), findsWidgets);
  });

  testWidgets('typography reflow retains the exact global scalar anchor', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final text = List.generate(
      240,
      (index) => '😀 Chapter $index preserves the reader position. ',
    ).join();
    final repository = FakeReaderRepository(
      content: FakeReaderRepository.textContent(text: text),
      progress: const ReadingProgress(
        currentPosition: '1800',
        progressPercentage: 20,
        totalReadingTimeSeconds: 0,
      ),
    );
    await pumpReader(tester, repository: repository);

    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Increase Font size'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 100));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bookmark this position'));
    await tester.pump();

    expect(repository.lastCreatedBookmarkAnchor, '1800');
  });

  testWidgets('bookmark jump immediately persists the target anchor', (
    tester,
  ) async {
    final text = List.generate(
      240,
      (index) => 'Chapter $index preserves the reader position. ',
    ).join();
    final repository = FakeReaderRepository(
      content: FakeReaderRepository.textContent(text: text),
      bookmarks: [
        Bookmark(
          id: 'bm-jump',
          anchor: '1800',
          createdAt: DateTime(2026),
          label: 'Jump target',
        ),
      ],
    );
    await pumpReader(tester, repository: repository);

    await tester.tap(find.byTooltip('Bookmarks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jump target'));
    await tester.pumpAndSettle();

    expect(repository.lastSaved?.currentPosition, '1800');
  });

  testWidgets('bookmarking a position lists contextual information', (
    tester,
  ) async {
    await pumpReader(tester, repository: FakeReaderRepository());

    await tester.tap(find.byTooltip('Bookmark this position'));
    await tester.pump();
    await tester.tap(find.byTooltip('Bookmarks'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BookmarksSheet),
        matching: find.textContaining('bright cold day'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('% through'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('bookmark fallback preview uses Unicode scalar anchors', (
    tester,
  ) async {
    const text = '😀😀Target passage starts here.';
    final repository = FakeReaderRepository(
      content: FakeReaderRepository.textContent(text: text),
      bookmarks: [
        Bookmark(id: 'bm-unicode', anchor: '2', createdAt: DateTime(2026)),
      ],
    );
    await pumpReader(tester, repository: repository);

    await tester.tap(find.byTooltip('Bookmarks'));
    await tester.pumpAndSettle();

    expect(find.text('Target passage starts here.'), findsOneWidget);
  });

  testWidgets('created bookmark labels truncate on Unicode scalar boundaries', (
    tester,
  ) async {
    final prefix = List.filled(70, 'a').join();
    final text = '$prefix😀 trailing text';
    final repository = FakeReaderRepository(
      content: FakeReaderRepository.textContent(text: text),
    );
    await pumpReader(tester, repository: repository);

    await tester.tap(find.byTooltip('Bookmark this position'));
    await tester.pump();

    final label = repository.lastCreatedBookmarkLabel!;
    expect(label.runes.length, 72);
    expect(label, '$prefix😀…');
    expect(label.runes, isNot(contains(0xFFFD)));
  });

  testWidgets('Explain is persistently discoverable on phone and desktop', (
    tester,
  ) async {
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      await tester.binding.setSurfaceSize(size);
      await pumpReader(tester, repository: FakeReaderRepository());

      expect(find.widgetWithText(FilledButton, 'Explain'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('bookmark deletion offers undo and restores the bookmark', (
    tester,
  ) async {
    final repository = FakeReaderRepository(
      bookmarks: [
        Bookmark(
          id: 'bm-1',
          anchor: '12',
          createdAt: DateTime(2026),
          label: 'bright cold day in April',
        ),
      ],
    );
    await pumpReader(tester, repository: repository);

    await tester.tap(find.byTooltip('Bookmarks'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete bookmark'));
    await tester.pumpAndSettle();

    expect(find.text('Bookmark deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('bright cold day in April'), findsOneWidget);
  });
}
