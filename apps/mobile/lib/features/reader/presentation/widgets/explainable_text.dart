import 'package:flutter/material.dart';

/// Renders reading text and lets the reader select any amount — a word (via
/// double-tap or long-press), multiple words, a sentence, or a paragraph (via
/// drag) — then explain it through the selection toolbar's "Explain" action.
///
/// The backend classifies the selection type; the UI never exposes modes.
///
/// Once a passage has been explained its range stays washed in
/// [highlightColor], so when the explanation sheet is open (or has been
/// dismissed) the reader can still see exactly which words the answer is
/// about. Losing that link is the most common failure of "ask about this text"
/// interfaces.
class ExplainableText extends StatefulWidget {
  const ExplainableText({
    required this.text,
    required this.style,
    required this.explainLabel,
    required this.onExplain,
    required this.highlightColor,
    this.highlightStart,
    this.highlightEnd,
    super.key,
  });

  final String text;
  final TextStyle style;
  final String explainLabel;

  /// Called with the selected text and its `[start, end)` offsets.
  final void Function(String text, int start, int end) onExplain;

  /// Wash applied to the most recently explained range.
  final Color highlightColor;

  /// Start of the explained range, if any.
  final int? highlightStart;

  /// End of the explained range, if any.
  final int? highlightEnd;

  @override
  State<ExplainableText> createState() => _ExplainableTextState();
}

class _ExplainableTextState extends State<ExplainableText> {
  TextSelection? _selection;

  void _handleExplain() {
    final selection = _selection;
    if (selection == null || !selection.isValid || selection.isCollapsed) {
      return;
    }
    final start = selection.start.clamp(0, widget.text.length);
    final end = selection.end.clamp(0, widget.text.length);
    final selected = widget.text.substring(start, end).trim();
    if (selected.isEmpty) {
      return;
    }
    widget.onExplain(selected, start, end);
  }

  /// Split the body into up to three spans so the explained range can carry a
  /// background without breaking selection offsets (offsets are preserved
  /// because the spans are contiguous slices of the same string).
  InlineSpan _buildSpan() {
    final start = widget.highlightStart;
    final end = widget.highlightEnd;
    final length = widget.text.length;

    final hasHighlight =
        start != null &&
        end != null &&
        start >= 0 &&
        end <= length &&
        start < end;

    if (!hasHighlight) {
      return TextSpan(text: widget.text, style: widget.style);
    }

    return TextSpan(
      style: widget.style,
      children: [
        if (start > 0) TextSpan(text: widget.text.substring(0, start)),
        TextSpan(
          text: widget.text.substring(start, end),
          style: TextStyle(backgroundColor: widget.highlightColor),
        ),
        if (end < length) TextSpan(text: widget.text.substring(end)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      _buildSpan() as TextSpan,
      style: widget.style,
      onSelectionChanged: (selection, _) => _selection = selection,
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: [
            ContextMenuButtonItem(
              label: widget.explainLabel,
              onPressed: () {
                ContextMenuController.removeAny();
                _handleExplain();
              },
            ),
            ...editableTextState.contextMenuButtonItems,
          ],
        );
      },
    );
  }
}
