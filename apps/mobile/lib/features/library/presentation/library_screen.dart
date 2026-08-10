import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_semantics.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/formatters/reading_time.dart';
import '../../auth/application/auth_controller.dart';
import '../../reader/application/reader_providers.dart';
import '../application/library_controller.dart';
import '../application/upload_controller.dart';
import '../domain/book.dart';
import 'widgets/book_card.dart';
import 'widgets/upload_status_card.dart';

/// The reader's library: resume first, everything else second.
///
/// The single most likely reason to open this app is to carry on with the book
/// already being read, so that book gets a card of its own at the top with its
/// progress and an explicit Continue action. Browsing the rest of the shelf is
/// the secondary task and sits below it.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    await ref.read(uploadControllerProvider.notifier).pickAndUpload();
  }

  void _open(Book book) {
    context.goNamed(
      AppRoutes.bookDetailName,
      pathParameters: {'bookId': book.id},
    );
  }

  void _read(Book book) {
    context.goNamed(AppRoutes.readerName, pathParameters: {'bookId': book.id});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final books = ref.watch(libraryControllerProvider);
    final upload = ref.watch(uploadControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          IconButton(
            tooltip: l10n.signOut,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
          const SizedBox(width: Space.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _upload,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.uploadBook),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(libraryControllerProvider.notifier).refresh(),
        child: switch (books) {
          AsyncValue(hasValue: true, value: final items?) => _LibraryBody(
            books: items,
            query: _query,
            searchController: _search,
            upload: upload,
            onQueryChanged: (value) => setState(() => _query = value),
            onOpen: _open,
            onRead: _read,
            onUpload: _upload,
            onRetryProcessing: (book) => ref
                .read(libraryControllerProvider.notifier)
                .retryProcessing(book.id),
          ),
          AsyncValue(hasError: true) => _LibraryError(
            onRetry: () =>
                ref.read(libraryControllerProvider.notifier).refresh(),
          ),
          _ => const _LibrarySkeleton(key: ValueKey('library-skeleton')),
        },
      ),
    );
  }
}

class _LibraryBody extends StatelessWidget {
  const _LibraryBody({
    required this.books,
    required this.query,
    required this.searchController,
    required this.upload,
    required this.onQueryChanged,
    required this.onOpen,
    required this.onRead,
    required this.onUpload,
    required this.onRetryProcessing,
  });

  final List<Book> books;
  final String query;
  final TextEditingController searchController;
  final UploadJob? upload;
  final ValueChanged<String> onQueryChanged;
  final void Function(Book) onOpen;
  final void Function(Book) onRead;
  final VoidCallback onUpload;
  final void Function(Book) onRetryProcessing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final normalized = query.trim().toLowerCase();
    final visible = normalized.isEmpty
        ? books
        : books
              .where(
                (book) =>
                    book.title.toLowerCase().contains(normalized) ||
                    book.originalFilename.toLowerCase().contains(normalized),
              )
              .toList();

    final continueBook = books
        .where((book) => book.status.isReadable)
        .firstOrNull;
    final showHero = continueBook != null && normalized.isEmpty;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (upload != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.sm,
                Space.lg,
                0,
              ),
              child: UploadStatusCard(job: upload!),
            ),
          ),

        if (showHero)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.base,
                Space.lg,
                0,
              ),
              child: _ContinueReadingCard(
                book: continueBook,
                onRead: () => onRead(continueBook),
                onDetails: () => onOpen(continueBook),
              ),
            ),
          ),

        if (books.isEmpty && upload == null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _LibraryEmpty(onUpload: onUpload),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.xl,
                Space.lg,
                Space.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      showHero ? l10n.libraryAllBooks : l10n.libraryTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    l10n.libraryBookCount(books.length),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.semantics.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (books.length > 3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  0,
                  Space.lg,
                  Space.md,
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onQueryChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.librarySearchHint,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.cancel,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              searchController.clear();
                              onQueryChanged('');
                            },
                          ),
                  ),
                ),
              ),
            ),
          if (visible.isEmpty)
            SliverToBoxAdapter(child: _NoResults(query: query))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                0,
                Space.lg,
                Space.huge + Space.xxl,
              ),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.md),
                itemBuilder: (context, index) => BookCard(
                  book: visible[index],
                  onTap: () => onOpen(visible[index]),
                  onRetryProcessing: () => onRetryProcessing(visible[index]),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// The resume card. Progress is fetched for this one book only: the list
/// endpoint returns no progress, and requesting it for every book on the shelf
/// would be an N+1 on every library visit.
class _ContinueReadingCard extends ConsumerWidget {
  const _ContinueReadingCard({
    required this.book,
    required this.onRead,
    required this.onDetails,
  });

  final Book book;
  final VoidCallback onRead;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;
    final progress = ref.watch(readingProgressProvider(book.id)).value;
    final fraction = ((progress?.progressPercentage ?? 0) / 100).clamp(
      0.0,
      1.0,
    );
    final started = fraction > 0.001;

    return Container(
      padding: const EdgeInsets.all(Space.base),
      decoration: BoxDecoration(
        color: semantics.surface,
        borderRadius: Radii.all(Radii.lg),
        border: Border.all(color: semantics.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (started ? l10n.libraryContinueReading : l10n.libraryStartReading)
                .toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: semantics.accent,
            ),
          ),
          const SizedBox(height: Space.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                height: 78,
                child: BookCover(book: book, compact: true),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: Space.sm),
                    if (started) ...[
                      ClipRRect(
                        borderRadius: Radii.all(Radii.pill),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 4,
                          backgroundColor: semantics.surfaceSunken,
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      Text(
                        '${l10n.readerPercentRead((fraction * 100).round())}'
                        '  ·  ${_remaining(context, l10n, fraction)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: semantics.inkMuted,
                        ),
                      ),
                    ] else
                      Text(
                        l10n.libraryNotStarted,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: semantics.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.base),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRead,
                  icon: const Icon(Icons.chrome_reader_mode_outlined, size: 18),
                  label: Text(started ? l10n.libraryResume : l10n.readBook),
                ),
              ),
              const SizedBox(width: Space.sm),
              IconButton(
                tooltip: l10n.bookDetailTitle,
                onPressed: onDetails,
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _remaining(
    BuildContext context,
    AppLocalizations l10n,
    double fraction,
  ) {
    // The reader endpoint owns character counts; the library only knows pages,
    // so an estimate is only offered when the backend supplied a page count.
    final pages = book.totalPages;
    if (pages == null || pages == 0) return l10n.libraryKeepGoing;
    final minutes = ReadingTime.minutesRemaining(pages * 1800, fraction);
    return minutes == 0
        ? l10n.readerAlmostDone
        : l10n.readerMinutesLeft(minutes);
  }
}

class _LibraryEmpty extends StatelessWidget {
  const _LibraryEmpty({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.xxl,
          Space.xxl,
          Space.xxl,
          Space.huge,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 32,
                color: semantics.inkFaint,
              ),
              const SizedBox(height: Space.base),
              Text(
                l10n.libraryEmptyTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.sm),
              Text(
                l10n.libraryEmptyMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: semantics.inkMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.xl),
              FilledButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: Text(l10n.uploadBook),
              ),
              const SizedBox(height: Space.md),
              // Says what will actually work before the reader spends time
              // picking a file the reader cannot yet render.
              Text(
                l10n.libraryFormatHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: semantics.inkFaint,
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

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.xxl,
      ),
      child: Column(
        children: [
          Text(
            l10n.libraryNoResults(query),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xs),
          Text(
            l10n.libraryNoResultsHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.semantics.inkMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Shaped placeholders in the same rhythm as the real list, so the screen does
/// not jump when the books arrive.
class _LibrarySkeleton extends StatelessWidget {
  const _LibrarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final semantics = context.semantics;

    Widget block(double height, {double radius = Radii.md}) => Container(
      height: height,
      decoration: BoxDecoration(
        color: semantics.surfaceSunken,
        borderRadius: Radii.all(radius),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        block(150, radius: Radii.lg),
        const SizedBox(height: Space.xl),
        block(18),
        const SizedBox(height: Space.md),
        for (var index = 0; index < 3; index++) ...[
          block(96, radius: Radii.lg),
          const SizedBox(height: Space.md),
        ],
      ],
    );
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return ListView(
      padding: const EdgeInsets.all(Space.xxl),
      children: [
        const SizedBox(height: Space.xxl),
        Icon(Icons.cloud_off_rounded, size: 32, color: semantics.inkFaint),
        const SizedBox(height: Space.base),
        Text(
          l10n.libraryLoadError,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.sm),
        Text(
          l10n.connectionHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: semantics.inkMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.xl),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.retry),
          ),
        ),
      ],
    );
  }
}
