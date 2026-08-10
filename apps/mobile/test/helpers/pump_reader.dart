import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readme_ai/core/preferences/preferences_service.dart';
import 'package:readme_ai/core/state/retry_policy.dart';
import 'package:readme_ai/core/theme/app_theme.dart';
import 'package:readme_ai/features/explanation/application/explanation_providers.dart';
import 'package:readme_ai/features/explanation/domain/explanation_repository.dart';
import 'package:readme_ai/features/reader/application/reader_providers.dart';
import 'package:readme_ai/features/reader/domain/reader_repository.dart';
import 'package:readme_ai/features/reader/presentation/reader_screen.dart';
import 'package:readme_ai/l10n/generated/app_localizations.dart';

import 'test_preferences.dart';

/// Pump the [ReaderScreen] inside a minimal app with fakes for the reader and
/// (optionally) explanation repositories. Returns the container so tests can
/// read providers.
///
/// The coach mark is marked as already seen by default so it does not sit over
/// the controls tests want to tap; pass [showExplainHint] to exercise it.
Future<ProviderContainer> pumpReader(
  WidgetTester tester, {
  required ReaderRepository repository,
  ExplanationRepository? explanationRepository,
  String bookId = 'b1',
  bool showExplainHint = false,
}) async {
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: [
      preferencesProvider.overrideWithValue(
        await testPreferences({
          PreferenceKeys.explainHintSeen: !showExplainHint,
        }),
      ),
      readerRepositoryProvider.overrideWithValue(repository),
      if (explanationRepository != null)
        explanationRepositoryProvider.overrideWithValue(explanationRepository),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReaderScreen(bookId: bookId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
