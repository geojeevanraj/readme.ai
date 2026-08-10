import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_service.dart';
import '../../../core/theme/app_semantics.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/appearance_controller.dart';
import '../../../core/theme/reading_palette.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/formatters/reading_time.dart';
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

/// Immersive, API-backed reader with contextual AI assistance.
///
/// The page is the interface. Chrome (title bar, controls) is transient: it
/// hides when the reader scrolls forward, returns when they scroll back, and
/// can be toggled with a tap. What remains at all times is a single quiet
/// footer line — percentage read and minutes left — because "where am I and how
/// much is left" is the one question a reader asks constantly.
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
  bool _chromeVisible = true;
  bool _showExplainHint = false;
  double _progress = 0;
  int _characterCount = 0;

  /// Range of the passage most recently sent for explanation, kept highlighted.
  int? _explainedStart;
  int? _explainedEnd;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesProvider);
    _showExplainHint =
        !(prefs.readBool(PreferenceKeys.explainHintSeen) ?? false);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _persistPosition();
    _scrollController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- position ---

  double get _scrollFraction {
    if (!_scrollController.hasClients) return 0;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return 0;
    return (_scrollController.offset / max).clamp(0.0, 1.0);
  }

  int _offsetFromFraction(double fraction) =>
      (fraction * _characterCount).round();

  void _onScroll() {
    final fraction = _scrollFraction;
    if (fraction != _progress) {
      setState(() => _progress = fraction);
    }
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 1200), _persistPosition);
  }

  void _persistPosition() {
    if (!_scrollController.hasClients || _characterCount == 0) return;
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
    if (_restored) return;
    _restored = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || !mounted) return;
      final max = _scrollController.position.maxScrollExtent;
      final target = (percentage / 100).clamp(0.0, 1.0) * max;
      _scrollController.jumpTo(target);
      setState(() => _progress = percentage / 100);
    });
  }

  void _seekTo(double fraction) {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(
      fraction.clamp(0.0, 1.0) * _scrollController.position.maxScrollExtent,
    );
    setState(() => _progress = fraction);
  }

  void _jumpToAnchor(String anchor) {
    final offset = int.tryParse(anchor) ?? 0;
    if (_characterCount == 0 || !_scrollController.hasClients) return;
    final fraction = (offset / _characterCount).clamp(0.0, 1.0);
    _scrollController.animateTo(
      fraction * _scrollController.position.maxScrollExtent,
      duration: Motion.of(context, Motion.slow),
      curve: Motion.standard,
    );
  }

  // ---------------------------------------------------------------- chrome ---

  void _toggleChrome() => setState(() => _chromeVisible = !_chromeVisible);

  bool _handleUserScroll(UserScrollNotification notification) {
    switch (notification.direction) {
      case ScrollDirection.forward:
        if (!_chromeVisible) setState(() => _chromeVisible = true);
      case ScrollDirection.reverse:
        if (_chromeVisible) setState(() => _chromeVisible = false);
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  void _dismissExplainHint() {
    ref
        .read(preferencesProvider)
        .writeBool(PreferenceKeys.explainHintSeen, value: true);
    setState(() => _showExplainHint = false);
  }

  // --------------------------------------------------------------- actions ---

  Future<void> _addBookmark() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final offset = _offsetFromFraction(_scrollFraction);
    await ref
        .read(readerControllerProvider)
        .addBookmark(widget.bookId, anchor: offset.toString());
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.bookmarkAdded),
          action: SnackBarAction(
            label: l10n.bookmarks,
            onPressed: _openBookmarks,
          ),
        ),
      );
  }

  void _openBookmarks() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BookmarksSheet(
        bookId: widget.bookId,
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
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ReaderSettingsSheet(),
    );
  }

  void _explainSelection(String text, int start, int end) {
    setState(() {
      _explainedStart = start;
      _explainedEnd = end;
      if (_showExplainHint) _dismissExplainHint();
    });

    final args = (
      bookId: widget.bookId,
      anchor: start.toString(),
      endAnchor: end.toString(),
      selectedText: text,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // A light barrier keeps the highlighted passage readable above the sheet:
      // the answer and the question stay on screen together.
      barrierColor: context.semantics.shadow.withValues(alpha: 0.16),
      builder: (_) => ExplanationSheet(
        args: args,
        onSave: () => _saveExplanation(start, text),
      ),
    );
  }

  Future<void> _saveExplanation(int anchor, String selectedText) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(readerControllerProvider)
        .addBookmark(
          widget.bookId,
          anchor: anchor.toString(),
          label: selectedText,
        );
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.explanationSaved)));
  }

  // ----------------------------------------------------------------- build ---

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(readingPaletteProvider);
    final contentState = ref.watch(bookContentProvider(widget.bookId));

    return Scaffold(
      backgroundColor: palette.canvas,
      body: AnimatedSwitcher(
        duration: Motion.of(context, Motion.base),
        child: switch (contentState) {
          AsyncValue(hasValue: true, :final value?) => _buildReader(
            context,
            palette,
            value,
          ),
          AsyncValue(hasError: true) => _ReaderMessage(
            key: const ValueKey('reader-error'),
            icon: Icons.cloud_off_rounded,
            title: AppLocalizations.of(context).libraryLoadError,
            message: AppLocalizations.of(context).connectionHint,
            onRetry: () => ref.invalidate(bookContentProvider(widget.bookId)),
          ),
          _ => const _ReaderLoading(key: ValueKey('reader-loading')),
        },
      ),
    );
  }

  Widget _buildReader(
    BuildContext context,
    ReadingPalette palette,
    BookContent content,
  ) {
    final l10n = AppLocalizations.of(context);

    if (content.format != ContentFormat.text || content.text == null) {
      return _ReaderMessage(
        key: const ValueKey('reader-unsupported'),
        icon: Icons.picture_as_pdf_outlined,
        title: l10n.readerUnsupportedFormat,
        message: l10n.readerUnsupportedFormatDetail,
      );
    }

    _characterCount = content.characterCount;

    final resume = ref.watch(readingProgressProvider(widget.bookId)).value;
    if (resume != null) _restorePosition(resume.progressPercentage);

    final settings = ref.watch(readerSettingsProvider);
    final media = MediaQuery.of(context);
    final measure = Measure.forFontSize(settings.fontSize);
    final horizontal = ((media.size.width - measure) / 2).clamp(
      Space.lg,
      double.infinity,
    );

    return Stack(
      key: const ValueKey('reader-text'),
      children: [
        // 1. The page.
        NotificationListener<UserScrollNotification>(
          onNotification: _handleUserScroll,
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (_) {
              _onScroll();
              return false;
            },
            child: GestureDetector(
              // A tap that does not land on text toggles the chrome, the way a
              // physical book has no chrome at all.
              onTap: _toggleChrome,
              behavior: HitTestBehavior.translucent,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: horizontal,
                  right: horizontal,
                  top: media.padding.top + Space.huge,
                  bottom: media.padding.bottom + Space.huge + Space.xxl,
                ),
                child: ExplainableText(
                  text: content.text!,
                  explainLabel: l10n.explain,
                  highlightColor: context.semantics.explainHighlight,
                  highlightStart: _explainedStart,
                  highlightEnd: _explainedEnd,
                  onExplain: _explainSelection,
                  style: AppTypography.reading(
                    fontSize: settings.fontSize,
                    lineHeight: settings.lineHeight,
                    color: palette.ink,
                    serif: settings.typeface.isSerif,
                  ),
                ),
              ),
            ),
          ),
        ),

        // 2. Persistent, quiet position line.
        _ReaderFooter(
          palette: palette,
          progress: _progress,
          characterCount: _characterCount,
          dimmed: _chromeVisible,
        ),

        // 3. Transient chrome.
        _ReaderTopBar(
          visible: _chromeVisible,
          palette: palette,
          title: content.title,
          onBookmark: _addBookmark,
          onBookmarks: _openBookmarks,
          onSettings: _openSettings,
        ),
        _ReaderControls(
          visible: _chromeVisible,
          palette: palette,
          progress: _progress,
          characterCount: _characterCount,
          onSeek: _seekTo,
          onSeekEnd: _persistPosition,
        ),

        // 4. One-time teaching moment for the product's core interaction.
        if (_showExplainHint)
          _ExplainCoachMark(palette: palette, onDismiss: _dismissExplainHint),
      ],
    );
  }
}

/// Top chrome: back, title, and the three reading actions.
class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({
    required this.visible,
    required this.palette,
    required this.title,
    required this.onBookmark,
    required this.onBookmarks,
    required this.onSettings,
  });

  final bool visible;
  final ReadingPalette palette;
  final String title;
  final VoidCallback onBookmark;
  final VoidCallback onBookmarks;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: _Chrome(
        visible: visible,
        slideFrom: -1,
        child: Container(
          color: palette.canvas.withValues(alpha: 0.96),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.sm,
                vertical: Space.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: palette.ink,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.inkMuted,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.bookmarkThisPosition,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    color: palette.ink,
                    onPressed: onBookmark,
                  ),
                  IconButton(
                    tooltip: l10n.bookmarks,
                    icon: const Icon(Icons.bookmarks_outlined),
                    color: palette.ink,
                    onPressed: onBookmarks,
                  ),
                  IconButton(
                    tooltip: l10n.readerSettings,
                    icon: const Icon(Icons.text_fields_rounded),
                    color: palette.ink,
                    onPressed: onSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom chrome: a scrubber for coarse navigation.
///
/// The backend serves a book as one text blob with no chapter structure, so a
/// table of contents is not possible yet; a scrubber gives the same "jump
/// somewhere else" capability with the data that exists.
class _ReaderControls extends StatelessWidget {
  const _ReaderControls({
    required this.visible,
    required this.palette,
    required this.progress,
    required this.characterCount,
    required this.onSeek,
    required this.onSeekEnd,
  });

  final bool visible;
  final ReadingPalette palette;
  final double progress;
  final int characterCount;
  final ValueChanged<double> onSeek;
  final VoidCallback onSeekEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final percent = (progress * 100).round();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: _Chrome(
        visible: visible,
        slideFrom: 1,
        child: Container(
          decoration: BoxDecoration(
            color: palette.canvas.withValues(alpha: 0.96),
            border: Border(top: BorderSide(color: palette.hairline)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.sm,
                Space.md,
                Space.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${l10n.readerPercentRead(percent)}  ·  '
                    '${_remainingLabel(l10n)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.inkMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Semantics(
                    label: l10n.readerPosition,
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      label: l10n.readerPercentRead(percent),
                      semanticFormatterCallback: (value) =>
                          l10n.readerPercentRead((value * 100).round()),
                      onChanged: onSeek,
                      onChangeEnd: (_) => onSeekEnd(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _remainingLabel(AppLocalizations l10n) {
    final minutes = ReadingTime.minutesRemaining(characterCount, progress);
    if (minutes == 0) {
      return progress >= 0.999 ? l10n.readerFinished : l10n.readerAlmostDone;
    }
    return l10n.readerMinutesLeft(minutes);
  }
}

/// The one piece of chrome that never leaves: how far in, how much left.
class _ReaderFooter extends StatelessWidget {
  const _ReaderFooter({
    required this.palette,
    required this.progress,
    required this.characterCount,
    required this.dimmed,
  });

  final ReadingPalette palette;
  final double progress;
  final int characterCount;

  /// True while the full controls are showing, in which case this line steps
  /// back to avoid saying the same thing twice.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final percent = (progress * 100).round();
    final minutes = ReadingTime.minutesRemaining(characterCount, progress);

    final remaining = switch (minutes) {
      0 when progress >= 0.999 => l10n.readerFinished,
      0 => l10n.readerAlmostDone,
      _ => l10n.readerMinutesLeft(minutes),
    };

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: dimmed ? 0 : 1,
          duration: Motion.of(context, Motion.base),
          curve: Motion.standard,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Text(
                '${l10n.readerPercentRead(percent)}  ·  $remaining',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.inkMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared show/hide animation for the reader's chrome.
class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.visible,
    required this.slideFrom,
    required this.child,
  });

  final bool visible;

  /// -1 slides up out of the top, 1 slides down out of the bottom.
  final double slideFrom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, Motion.base);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : Offset(0, slideFrom),
        duration: duration,
        curve: Motion.standard,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: duration,
          curve: Motion.standard,
          child: child,
        ),
      ),
    );
  }
}

/// One-time coach mark that teaches the select → Explain gesture.
class _ExplainCoachMark extends StatelessWidget {
  const _ExplainCoachMark({required this.palette, required this.onDismiss});

  final ReadingPalette palette;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return Positioned(
      left: Space.base,
      right: Space.base,
      bottom: Space.huge + Space.base,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Space.base,
          Space.md,
          Space.sm,
          Space.md,
        ),
        decoration: BoxDecoration(
          color: semantics.surface,
          borderRadius: Radii.all(Radii.lg),
          border: Border.all(color: semantics.hairline),
          boxShadow: Shadows.floating(semantics.shadow),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: Space.xxs),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: semantics.accent,
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.readerExplainHintTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: Space.xxs),
                  Text(
                    l10n.readerExplainHintBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: semantics.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.sm),
            TextButton(
              onPressed: onDismiss,
              child: Text(l10n.readerExplainHintDismiss),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton-free, quiet loading state: a reader is about to read, not to watch
/// a spinner, so this is deliberately minimal and centred.
class _ReaderLoading extends StatelessWidget {
  const _ReaderLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: context.semantics.inkFaint,
        ),
      ),
    );
  }
}

/// Full-bleed message for reader-level errors and unsupported formats.
class _ReaderMessage extends StatelessWidget {
  const _ReaderMessage({
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(Space.xxl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 32, color: semantics.inkFaint),
                    const SizedBox(height: Space.base),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: Space.sm),
                      Text(
                        message!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: semantics.inkMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (onRetry != null) ...[
                      const SizedBox(height: Space.xl),
                      OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
