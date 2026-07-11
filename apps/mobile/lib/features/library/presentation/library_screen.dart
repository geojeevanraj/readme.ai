import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/files/file_picker_service.dart';
import '../../../core/router/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../application/library_controller.dart';
import '../domain/book.dart';
import 'widgets/book_card.dart';

/// The user's library — the authenticated landing screen.
///
/// Renders loading, error, empty, and populated states, supports pull-to-
/// refresh, and offers an upload action.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final booksState = ref.watch(libraryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          IconButton(
            tooltip: l10n.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleUpload(context, ref),
        icon: const Icon(Icons.upload_file),
        label: Text(l10n.uploadBook),
      ),
      body: switch (booksState) {
        AsyncData(:final value) => _LibraryBody(
          books: value,
          onRefresh: () =>
              ref.read(libraryControllerProvider.notifier).refresh(),
          onOpen: (book) => _openBook(context, book),
          onUpload: () => _handleUpload(context, ref),
        ),
        AsyncError() => _ErrorView(
          message: l10n.libraryLoadError,
          onRetry: () => ref.read(libraryControllerProvider.notifier).refresh(),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  void _openBook(BuildContext context, Book book) {
    context.goNamed(
      AppRoutes.bookDetailName,
      pathParameters: {'bookId': book.id},
    );
  }

  Future<void> _handleUpload(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ref.read(filePickerProvider).pickBook();
    if (picked == null) {
      return;
    }
    try {
      await ref.read(libraryControllerProvider.notifier).uploadBook(picked);
    } on Object {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.uploadFailed)));
    }
  }
}

class _LibraryBody extends StatelessWidget {
  const _LibraryBody({
    required this.books,
    required this.onRefresh,
    required this.onOpen,
    required this.onUpload,
  });

  final List<Book> books;
  final Future<void> Function() onRefresh;
  final void Function(Book) onOpen;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: _EmptyView(onUpload: onUpload),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return BookCard(book: book, onTap: () => onOpen(book));
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Wrapped in a scroll view so pull-to-refresh works even when empty.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.libraryEmptyTitle,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.libraryEmptyMessage,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file),
                  label: Text(l10n.uploadBook),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
