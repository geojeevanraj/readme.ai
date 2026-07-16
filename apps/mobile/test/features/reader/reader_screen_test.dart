import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readme_ai/core/theme/theme_mode_controller.dart';
import 'package:readme_ai/features/reader/application/reader_settings_controller.dart';
import 'package:readme_ai/features/reader/domain/bookmark.dart';
import 'package:readme_ai/features/reader/presentation/widgets/bookmarks_sheet.dart';

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
