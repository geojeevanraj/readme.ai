import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../explanation/presentation/explanation_sheet.dart';
import '../application/reader_controller.dart';
import '../application/reader_providers.dart';
import '../application/reader_settings_controller.dart';
import '../domain/book_content.dart';
import '../domain/bookmark.dart';
import '../domain/character_anchor.dart';
import '../domain/content_format.dart';
import 'pagination/document_paginator.dart';
import 'widgets/bookmarks_sheet.dart';
import 'widgets/explainable_text.dart';
import 'widgets/page_turn_view.dart';
import 'widgets/reader_settings_sheet.dart';

/// Immersive, API-backed reader with contextual AI assistance.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({required this.bookId, super.key});

  final String bookId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  static const _paginator = DocumentPaginator();

  final Stopwatch _sessionStopwatch = Stopwatch()..start();
  late final ReaderController _readerController;
  bool _restored = false;
  double _progress = 0;
  int _characterCount = 0;
  int _currentOffset = 0;
  String? _contentText;
  List<DocumentPage> _pages = const [];

  @override
  void initState() {
    super.initState();
    _readerController = ref.read(readerControllerProvider);
  }

  @override
  void dispose() {
    _persistPosition();
    super.dispose();
  }

  void _persistPosition() {
    if (_characterCount == 0) return;
    final fraction = (_currentOffset / _characterCount).clamp(0.0, 1.0);
    final seconds = _sessionStopwatch.elapsed.inSeconds;
    _sessionStopwatch
      ..reset()
      ..start();
    unawaited(
      _readerController.saveProgress(
        widget.bookId,
        currentPosition: _currentOffset.toString(),
        progressPercentage: fraction * 100,
        readingTimeSeconds: seconds,
      ),
    );
  }

  void _restorePosition(String anchor, double percentage) {
    if (_restored || _characterCount == 0) return;
    _restored = true;
    final savedOffset = int.tryParse(anchor);
    _currentOffset =
        (savedOffset ??
                ((percentage / 100).clamp(0.0, 1.0) * _characterCount).round())
            .clamp(0, _characterCount);
    _progress = (_currentOffset / _characterCount).clamp(0.0, 1.0);
  }

  void _jumpToAnchor(String anchor) {
    if (_characterCount == 0) return;
    final offset = (int.tryParse(anchor) ?? 0).clamp(0, _characterCount);
    setState(() {
      _currentOffset = offset;
      _progress = (_currentOffset / _characterCount).clamp(0.0, 1.0);
    });
    _persistPosition();
  }

  int _pageForOffset(List<DocumentPage> pages, int offset) {
    if (pages.isEmpty) return 0;
    final index = pages.indexWhere(
      (page) => offset >= page.startOffset && offset < page.endOffset,
    );
    return index == -1 ? pages.length - 1 : index;
  }

  void _onPageChanged(int index) {
    if (index < 0 || index >= _pages.length) return;
    setState(() {
      _currentOffset = _pages[index].startOffset;
      _progress = _characterCount == 0
          ? 0
          : (_currentOffset / _characterCount).clamp(0.0, 1.0);
    });
    _persistPosition();
  }

  Future<void> _addBookmark() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final offset = _currentOffset;
    final label = _passageAt(_contentText ?? '', offset, maxLength: 72);
    await ref
        .read(readerControllerProvider)
        .addBookmark(
          widget.bookId,
          anchor: offset.toString(),
          label: label.isEmpty ? null : label,
        );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.bookmarkAdded),
          action: SnackBarAction(label: 'View', onPressed: _openBookmarks),
        ),
      );
  }

  void _openBookmarks() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => BookmarksSheet(
        bookId: widget.bookId,
        contentText: _contentText,
        characterCount: _characterCount,
        onJump: (Bookmark bookmark) {
          Navigator.of(context).pop();
          _jumpToAnchor(bookmark.anchor);
        },
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const ReaderSettingsSheet(),
    );
  }

  void _explainSelection(String text, int start, int end) {
    final args = (
      bookId: widget.bookId,
      anchor: start.toString(),
      endAnchor: end.toString(),
      selectedText: text,
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ExplanationSheet(args: args),
    );
  }

  void _explainCurrentPassage() {
    final text = _contentText;
    if (text == null || text.isEmpty) return;
    final scalarOffset = _currentOffset.clamp(0, CharacterAnchor.length(text));
    final codeUnitOffset = CharacterAnchor.toCodeUnit(text, scalarOffset);
    final codeUnitStart = _paragraphStart(text, codeUnitOffset);
    final codeUnitEnd = _paragraphEnd(text, codeUnitOffset);
    final rawPassage = text.substring(codeUnitStart, codeUnitEnd);
    final leadingWhitespace = rawPassage.length - rawPassage.trimLeft().length;
    final trailingWhitespace =
        rawPassage.length - rawPassage.trimRight().length;
    final adjustedStart = codeUnitStart + leadingWhitespace;
    final adjustedEnd = codeUnitEnd - trailingWhitespace;
    final passage = text.substring(adjustedStart, adjustedEnd);
    if (passage.isNotEmpty) {
      _explainSelection(
        passage,
        CharacterAnchor.fromCodeUnit(text, adjustedStart),
        CharacterAnchor.fromCodeUnit(text, adjustedEnd),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contentState = ref.watch(bookContentProvider(widget.bookId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        backgroundColor: theme.colorScheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contentState.value?.title ?? l10n.appTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${(_progress * 100).round()}% complete',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.bookmarkThisPosition,
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: contentState.hasValue ? _addBookmark : null,
          ),
          IconButton(
            tooltip: l10n.bookmarks,
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: _openBookmarks,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: l10n.readerSettings,
              icon: const Icon(Icons.tune_rounded),
              onPressed: _openSettings,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 180),
            builder: (context, value, _) =>
                LinearProgressIndicator(minHeight: 3, value: value),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: switch (contentState) {
          AsyncData(:final value) => _buildContent(context, value),
          AsyncError() => _ReaderError(
            onRetry: () => ref.invalidate(bookContentProvider(widget.bookId)),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, BookContent content) {
    final l10n = AppLocalizations.of(context);
    if (content.format != ContentFormat.text || content.text == null) {
      return _UnsupportedView(
        key: const ValueKey('unsupported-reader'),
        message: l10n.readerUnsupportedFormat,
      );
    }

    _characterCount = CharacterAnchor.length(content.text!);
    _contentText = content.text;
    final progressAsync = ref.watch(readingProgressProvider(widget.bookId));
    final resume = progressAsync.value;
    if (resume != null) {
      _restorePosition(resume.currentPosition, resume.progressPercentage);
    }

    final settings = ref.watch(readerSettingsProvider);
    final theme = Theme.of(context);
    final textStyle =
        theme.textTheme.bodyLarge?.copyWith(
          fontSize: settings.fontSize,
          height: settings.lineHeight,
          letterSpacing: 0.05,
        ) ??
        TextStyle(fontSize: settings.fontSize, height: settings.lineHeight);

    return LayoutBuilder(
      key: const ValueKey('text-reader'),
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final outerHorizontal = isWide ? 32.0 : 12.0;
        final paperHorizontal = isWide ? 56.0 : 30.0;
        const paperVertical = 34.0;
        const footerHeight = 62.0;
        final bookWidth = (constraints.maxWidth - outerHorizontal * 2).clamp(
          1.0,
          860.0,
        );
        final bookHeight = (constraints.maxHeight - 24 - footerHeight).clamp(
          1.0,
          double.infinity,
        );
        final textSize = Size(
          (bookWidth - paperHorizontal * 2).clamp(1.0, double.infinity),
          (bookHeight - paperVertical * 2).clamp(1.0, double.infinity),
        );
        final pages = _paginator.paginate(
          text: content.text!,
          style: textStyle,
          pageSize: textSize,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.localeOf(context),
        );
        _pages = pages;
        final currentPage = _pageForOffset(pages, _currentOffset);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            outerHorizontal,
            12,
            outerHorizontal,
            12,
          ),
          child: Center(
            child: SizedBox(
              width: bookWidth,
              child: Column(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(isWide ? 18 : 10),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.10),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isWide ? 18 : 10),
                        child: PageTurnView(
                          itemCount: pages.length,
                          initialPage: currentPage,
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) {
                            final page = pages[index];
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: paperHorizontal,
                                vertical: paperVertical,
                              ),
                              child: ExplainableText(
                                text: page.text,
                                explainLabel: l10n.explain,
                                style: textStyle,
                                onExplain: (text, start, end) =>
                                    _explainSelection(
                                      text,
                                      page.startOffset +
                                          CharacterAnchor.fromCodeUnit(
                                            page.text,
                                            start,
                                          ),
                                      page.startOffset +
                                          CharacterAnchor.fromCodeUnit(
                                            page.text,
                                            end,
                                          ),
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: footerHeight,
                    child: Row(
                      children: [
                        Text(
                          'Page ${currentPage + 1} of ${pages.length}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.tonalIcon(
                          onPressed: _explainCurrentPassage,
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 17,
                          ),
                          label: const Text('Explain'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UnsupportedView extends StatelessWidget {
  const _UnsupportedView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 31,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Text-based PDF and plain-text files are supported. '
                'Scanned or encrypted files may need OCR or a password first.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _paragraphStart(String text, int offset) {
  if (text.isEmpty) return 0;
  final safeOffset = offset.clamp(0, text.length);
  final separator = text.lastIndexOf(
    '\n\n',
    safeOffset == 0 ? 0 : safeOffset - 1,
  );
  return separator == -1 ? 0 : separator + 2;
}

int _paragraphEnd(String text, int offset) {
  if (text.isEmpty) return 0;
  final separator = text.indexOf('\n\n', offset.clamp(0, text.length));
  return separator == -1 ? text.length : separator;
}

String _passageAt(String text, int offset, {required int maxLength}) {
  if (text.isEmpty) return '';
  final codeUnitOffset = CharacterAnchor.toCodeUnit(text, offset);
  final passage = text
      .substring(
        _paragraphStart(text, codeUnitOffset),
        _paragraphEnd(text, codeUnitOffset),
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final passageLength = CharacterAnchor.length(passage);
  if (passageLength <= maxLength) return passage;
  if (maxLength <= 1) return maxLength == 1 ? '…' : '';
  return '${CharacterAnchor.substring(passage, 0, maxLength - 1).trimRight()}…';
}

class _ReaderError extends StatelessWidget {
  const _ReaderError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 52),
          const SizedBox(height: 16),
          Text(l10n.libraryLoadError),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
