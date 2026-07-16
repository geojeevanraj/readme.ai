import 'explanation.dart';

/// Contract for requesting contextual explanations of a selection.
///
/// The reader depends on this interface only; the Dio-backed implementation
/// (which reaches the explanation API, never Ollama directly) is injected via
/// Riverpod so a fake can be used in tests.
abstract interface class ExplanationRepository {
  /// Explain the selected text; the backend classifies the selection type.
  Future<Explanation> explain({
    required String bookId,
    required String anchor,
    required String endAnchor,
    required String selectedText,
  });
}
