import 'package:flutter/material.dart';

/// Renders reading text and lets the reader select any amount — a word (via
/// double-tap or long-press), multiple words, a sentence, or a paragraph (via
/// drag) — then explain it through the selection toolbar's "Explain" action.
///
/// The backend classifies the selection type; the UI never exposes modes.
class ExplainableText extends StatefulWidget {
  const ExplainableText({
    required this.text,
    required this.style,
    required this.explainLabel,
    required this.onExplain,
    super.key,
  });

  final String text;
  final TextStyle style;
  final String explainLabel;

  /// Called with the selected text and its `[start, end)` offsets.
  final void Function(String text, int start, int end) onExplain;

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

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      widget.text,
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
