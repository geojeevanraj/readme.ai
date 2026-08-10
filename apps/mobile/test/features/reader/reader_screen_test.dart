import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readme_ai/core/preferences/preferences_service.dart';
import 'package:readme_ai/core/theme/appearance_controller.dart';
import 'package:readme_ai/core/theme/reading_palette.dart';
import 'package:readme_ai/features/reader/application/reader_settings.dart';
import 'package:readme_ai/features/reader/application/reader_settings_controller.dart';

import '../../helpers/fake_reader_repository.dart';
import '../../helpers/pump_reader.dart';

void main() {
  testWidgets('renders readable text content', (tester) async {
    await pumpReader(tester, repository: FakeReaderRepository());

    expect(find.textContaining('bright cold day in April'), findsOneWidget);
    expect(find.text('Nineteen Eighty-Four'), findsOneWidget);
  });

  testWidgets('shows how much reading is left, not just a percentage', (
    tester,
  ) async {
    await pumpReader(tester, repository: FakeReaderRepository());

    // Short fake book: under a minute of reading remains.
    expect(find.textContaining('Almost done'), findsWidgets);
    expect(find.textContaining('0% read'), findsWidgets);
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

  testWidgets('the explain coach mark is shown once and then remembered', (
    tester,
  ) async {
    final container = await pumpReader(
      tester,
      repository: FakeReaderRepository(),
      showExplainHint: true,
    );

    expect(find.text('Select any word or passage'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('Select any word or passage'), findsNothing);
    expect(
      container
          .read(preferencesProvider)
          .readBool(PreferenceKeys.explainHintSeen),
      isTrue,
    );
  });

  testWidgets('reader settings step the font size and persist it', (
    tester,
  ) async {
    final container = await pumpReader(
      tester,
      repository: FakeReaderRepository(),
    );
    final initial = container.read(readerSettingsProvider).fontSize;

    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Increase Text size'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Increase Text size'));
    await tester.pumpAndSettle();

    final updated = container.read(readerSettingsProvider).fontSize;
    expect(updated, greaterThan(initial));
    expect(
      container
          .read(preferencesProvider)
          .readDouble(PreferenceKeys.readerFontSize),
      updated,
    );
  });

  testWidgets('reader settings switch the reading face', (tester) async {
    final container = await pumpReader(
      tester,
      repository: FakeReaderRepository(),
    );

    expect(
      container.read(readerSettingsProvider).typeface,
      ReaderTypeface.serif,
    );

    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sans'));
    await tester.pumpAndSettle();

    expect(
      container.read(readerSettingsProvider).typeface,
      ReaderTypeface.sans,
    );
  });

  testWidgets('choosing Night puts the whole app into dark mode', (
    tester,
  ) async {
    final container = await pumpReader(
      tester,
      repository: FakeReaderRepository(),
    );

    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Night'));
    await tester.pumpAndSettle();

    expect(container.read(appearanceProvider), ReadingTheme.night);
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('bookmarking a position lists it with its location', (
    tester,
  ) async {
    await pumpReader(tester, repository: FakeReaderRepository());

    await tester.tap(find.byTooltip('Bookmark this position'));
    await tester.pump();

    await tester.tap(find.byTooltip('Bookmarks'));
    await tester.pumpAndSettle();

    expect(find.text('At 0%'), findsOneWidget);

    // Drain the confirmation snackbar's auto-dismiss timer.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
