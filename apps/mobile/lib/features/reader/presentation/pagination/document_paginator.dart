import 'package:flutter/material.dart';

import '../../domain/character_anchor.dart';

/// A viewport-sized slice of a document with stable global character offsets.
///
/// Offsets count Unicode scalar values, matching the backend anchor contract.
@immutable
class DocumentPage {
  const DocumentPage({
    required this.text,
    required this.startOffset,
    required this.endOffset,
  });

  final String text;
  final int startOffset;
  final int endOffset;
}

/// Converts logical document text into viewport-sized presentation pages.
///
/// Pagination never changes the source text or its global character anchors.
/// Pages are recalculated when typography or viewport constraints change.
class DocumentPaginator {
  const DocumentPaginator();

  List<DocumentPage> paginate({
    required String text,
    required TextStyle style,
    required Size pageSize,
    required TextDirection textDirection,
    TextScaler textScaler = TextScaler.noScaling,
    Locale? locale,
  }) {
    if (text.isEmpty) return const [];
    final boundaries = CharacterAnchor.codeUnitBoundaries(text);
    final characterCount = boundaries.length - 1;
    if (pageSize.width <= 0 || pageSize.height <= 0) {
      return [
        DocumentPage(text: text, startOffset: 0, endOffset: characterCount),
      ];
    }

    final pages = <DocumentPage>[];
    var start = 0;
    while (start < characterCount) {
      final fittingLength = _largestFittingScalarPrefix(
        text,
        boundaries: boundaries,
        start: start,
        characterCount: characterCount,
        style: style,
        pageSize: pageSize,
        textDirection: textDirection,
        textScaler: textScaler,
        locale: locale,
      );
      final rawEnd = (start + fittingLength).clamp(start + 1, characterCount);
      final end = rawEnd == characterCount
          ? rawEnd
          : _preferReadableBoundary(text, boundaries, start, rawEnd);
      pages.add(
        DocumentPage(
          text: text.substring(boundaries[start], boundaries[end]),
          startOffset: start,
          endOffset: end,
        ),
      );
      start = end;
    }
    return pages;
  }

  int _largestFittingScalarPrefix(
    String text, {
    required List<int> boundaries,
    required int start,
    required int characterCount,
    required TextStyle style,
    required Size pageSize,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required Locale? locale,
  }) {
    if (_fits(
      text.substring(boundaries[start], boundaries[characterCount]),
      style: style,
      pageSize: pageSize,
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
    )) {
      return characterCount - start;
    }

    var low = 1;
    var high = characterCount - start;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (_fits(
        text.substring(boundaries[start], boundaries[start + middle]),
        style: style,
        pageSize: pageSize,
        textDirection: textDirection,
        textScaler: textScaler,
        locale: locale,
      )) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }

  bool _fits(
    String text, {
    required TextStyle style,
    required Size pageSize,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required Locale? locale,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
    )..layout(maxWidth: pageSize.width);
    return painter.height <= pageSize.height + 0.01;
  }

  int _preferReadableBoundary(
    String text,
    List<int> boundaries,
    int start,
    int measuredEnd,
  ) {
    final searchStart = start + ((measuredEnd - start) * 0.72).floor();
    for (var index = measuredEnd; index > searchStart; index--) {
      final character = text.substring(
        boundaries[index - 1],
        boundaries[index],
      );
      if (character == '\n' || character == ' ' || character == '\t') {
        return index;
      }
    }
    return measuredEnd;
  }
}
