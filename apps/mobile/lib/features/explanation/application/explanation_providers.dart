import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/explanation_repository_impl.dart';
import '../domain/explanation.dart';
import '../domain/explanation_repository.dart';

/// Arguments identifying a single explanation request.
///
/// A record gives structural equality, so the family caches per unique
/// selection and de-duplicates identical requests.
typedef ExplanationArgs = ({
  String bookId,
  String anchor,
  String endAnchor,
  String selectedText,
});

/// Provides the [ExplanationRepository]. Overridden in tests with a fake.
final explanationRepositoryProvider = Provider<ExplanationRepository>((ref) {
  return ExplanationRepositoryImpl(ref.watch(dioProvider));
});

/// Loads the explanation for a specific selection.
///
/// Auto-disposed so the result clears once the bottom sheet closes; retry is a
/// simple `ref.invalidate` of this provider.
final explanationProvider = FutureProvider.autoDispose
    .family<Explanation, ExplanationArgs>((ref, args) {
      return ref
          .watch(explanationRepositoryProvider)
          .explain(
            bookId: args.bookId,
            anchor: args.anchor,
            endAnchor: args.endAnchor,
            selectedText: args.selectedText,
          );
    });
