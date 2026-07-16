import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readme_ai/features/explanation/application/explanation_providers.dart';
import 'package:readme_ai/features/explanation/domain/explanation.dart';
import 'package:readme_ai/features/explanation/domain/prerequisite.dart';
import 'package:readme_ai/features/explanation/domain/selection_type.dart';
import 'package:readme_ai/features/explanation/presentation/explanation_sheet.dart';
import 'package:readme_ai/l10n/generated/app_localizations.dart';

import '../../helpers/fake_explanation_repository.dart';

const _args = (
  bookId: 'b1',
  anchor: '10',
  endAnchor: '16',
  selectedText: 'laptop',
);

Future<void> _pumpSheet(
  WidgetTester tester,
  FakeExplanationRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [explanationRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ExplanationSheet(args: _args)),
      ),
    ),
  );
}

void main() {
  testWidgets('renders a word explanation with meaning and example', (
    tester,
  ) async {
    await _pumpSheet(tester, FakeExplanationRepository());
    await tester.pumpAndSettle();

    expect(find.text('a small portable computer'), findsOneWidget);
    expect(
      find.text('A laptop is a portable computer you can use anywhere.'),
      findsOneWidget,
    );
    expect(find.text('Winston opened his laptop to write.'), findsOneWidget);
  });

  testWidgets('renders a sentence explanation without meaning/example', (
    tester,
  ) async {
    final repository = FakeExplanationRepository()
      ..result = const Explanation(
        selectionType: SelectionType.sentence,
        explanation: 'This sentence means the day was cold and clear.',
      );

    await _pumpSheet(tester, repository);
    await tester.pumpAndSettle();

    expect(
      find.text('This sentence means the day was cold and clear.'),
      findsOneWidget,
    );
    expect(find.text('Meaning'), findsNothing);
    expect(find.text('Example'), findsNothing);
  });

  testWidgets('renders a paragraph (author intention) explanation', (
    tester,
  ) async {
    final repository = FakeExplanationRepository()
      ..result = const Explanation(
        selectionType: SelectionType.paragraph,
        explanation: 'The author is establishing a bleak, controlled world.',
      );

    await _pumpSheet(tester, repository);
    await tester.pumpAndSettle();

    expect(
      find.text('The author is establishing a bleak, controlled world.'),
      findsOneWidget,
    );
  });

  testWidgets('shows prerequisites in a collapsible section when present', (
    tester,
  ) async {
    final repository = FakeExplanationRepository()
      ..result = const Explanation(
        selectionType: SelectionType.word,
        explanation: 'Gradient descent optimizes parameters.',
        prerequisites: [
          Prerequisite(name: 'Derivative', reason: 'Builds on derivatives.'),
        ],
      );

    await _pumpSheet(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Prerequisites'), findsOneWidget);
    // Expand the section to reveal the concept.
    await tester.tap(find.text('Prerequisites'));
    await tester.pumpAndSettle();
    expect(find.text('Derivative'), findsOneWidget);
  });

  testWidgets('shows no prerequisites section when empty', (tester) async {
    await _pumpSheet(tester, FakeExplanationRepository());
    await tester.pumpAndSettle();

    expect(find.text('Prerequisites'), findsNothing);
  });

  testWidgets('shows a loading indicator while fetching', (tester) async {
    final repository = FakeExplanationRepository()..gate = Completer<void>();

    await _pumpSheet(tester, repository);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('a small portable computer'), findsOneWidget);
  });

  testWidgets('shows an error with retry, then recovers', (tester) async {
    final repository = FakeExplanationRepository()..error = Exception('boom');

    await _pumpSheet(tester, repository);
    await tester.pumpAndSettle();
    expect(find.textContaining("Couldn't explain"), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('a small portable computer'), findsOneWidget);
  });
}
