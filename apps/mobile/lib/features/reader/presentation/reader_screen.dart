import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../explanation/presentation/explanation_sheet.dart';
import '../application/reader_controller.dart';
import '../application/reader_providers.dart';
import '../application/reader_settings_controller.dart';
import '../domain/book_content.dart';
import '../domain/bookmark.dart';
import '../domain/content_format.dart';
import 'widgets/bookmarks_sheet.dart';
import 'widgets/explainable_text.dart';
import 'widgets/reader_settings_sheet.dart';

/// The immersive reading screen for a single book.
///
/// Renders reflowable text with adjustable typography, restores the saved
/// position on open, persists position as the user reads, and manages
/// bookmarks. There are deliberately no AI affordances or text-selection tools.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({required this.bookId, super.key});

  final String bookId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final Stopwatch _sessionStopwatch = Stopwatch()..start();
  Timer? _saveDebounce;
  bool _restored = false;
  double _progress = 0;
  int _characterCount = 0;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _persistPosition();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Position helpers --------------------------------------------------
  double get _scrollFraction {
    if (!_scrollController.hasClients) {
      return 0;
    }
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) {
      return 0;
    }
    return (_scrollController.offset / max).clamp(0.0, 1.0);
  }

  int _offsetFromFraction(double fraction) =>
      (fraction * _characterCount).round();

  void _onScroll() {
    final fraction = _scrollFraction;
    setState(() => _progress = fraction);
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 1200), _persistPosition);
  }

  void _persistPosition() {
    if (!_scrollController.hasClients || _characterCount == 0) {
      return;
    }
    final fraction = _scrollFraction;
    final seconds = _sessionStopwatch.elapsed.inSeconds;
    _sessionStopwatch
      ..reset()
      ..start();
    unawaited(
      ref
          .read(readerControllerProvider)
          .saveProgress(
            widget.bookId,
            currentPosition: _offsetFromFraction(fraction).toString(),
            progressPercentage: fraction * 100,
            readingTimeSeconds: seconds,
          ),
    );
  }

  void _restorePosition(double percentage) {
    if (_restored) {
      return;
    }
    _restored = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final max = _scrollController.position.maxScrollExtent;
      final target = (percentage / 100).clamp(0.0, 1.0) * max;
      _scrollController.jumpTo(target);
      setState(() => _progress = percentage / 100);
    });
  }

  void _jumpToAnchor(String anchor) {
    final offset = int.tryParse(anchor) ?? 0;
    if (_characterCount == 0 || !_scrollController.hasClients) {
      return;
    }
    final fraction = (offset / _characterCount).clamp(0.0, 1.0);
    _scrollController.animateTo(
      fraction * _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // --- Actions -----------------------------------------------------------
  Future<void> _addBookmark() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final offset = _offsetFromFraction(_scrollFraction);
    await ref
        .read(readerControllerProvider)
        .addBookmark(widget.bookId, anchor: offset.toString());
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.bookmarkAdded)));
  }

  void _openBookmarks() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => BookmarksSheet(
        bookId: widget.bookId,
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
      builder: (_) => ExplanationSheet(args: args),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contentState = ref.watch(bookContentProvider(widget.bookId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          contentState.value?.title ?? l10n.appTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          IconButton(
            tooltip: l10n.readerSettings,
            icon: const Icon(Icons.tune),
            onPressed: _openSettings,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(value: _progress.clamp(0.0, 1.0)),
        ),
      ),
      body: switch (contentState) {
        AsyncData(:final value) => _buildContent(context, value),
        AsyncError() => Center(child: Text(l10n.libraryLoadError)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildContent(BuildContext context, BookContent content) {
    final l10n = AppLocalizations.of(context);
    if (content.format != ContentFormat.text || content.text == null) {
      return _UnsupportedView(message: l10n.readerUnsupportedFormat);
    }

    _characterCount = content.characterCount;
    final progressAsync = ref.watch(readingProgressProvider(widget.bookId));
    final resume = progressAsync.value;
    if (resume != null) {
      _restorePosition(resume.progressPercentage);
    }

    final settings = ref.watch(readerSettingsProvider);
    final theme = Theme.of(context);

    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (_) {
        _onScroll();
        return false;
      },
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 64),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ExplainableText(
                text: content.text!,
                explainLabel: l10n.explain,
                style:
                    theme.textTheme.bodyLarge?.copyWith(
                      fontSize: settings.fontSize,
                      height: settings.lineHeight,
                    ) ??
                    TextStyle(fontSize: settings.fontSize),
                onExplain: _explainSelection,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnsupportedView extends StatelessWidget {
  const _UnsupportedView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
