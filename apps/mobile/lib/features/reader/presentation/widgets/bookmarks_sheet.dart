import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantics.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/reader_controller.dart';
import '../../application/reader_providers.dart';
import '../../domain/bookmark.dart';

/// Bottom sheet listing the book's saved positions.
///
/// Every entry answers "what is this?" before "where is this?": a saved
/// explanation shows the passage it was about, a plain bookmark shows how far
/// into the book it sits. Deleting is undoable, because a mis-tap on a small
/// delete button should not destroy something silently.
class BookmarksSheet extends ConsumerWidget {
  const BookmarksSheet({
    required this.bookId,
    required this.characterCount,
    required this.onJump,
    super.key,
  });

  final String bookId;

  /// Total characters in the book, used to express an anchor as a percentage.
  final int characterCount;

  final void Function(Bookmark) onJump;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;
    final bookmarks = ref.watch(bookmarksProvider(bookId));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.bookmarks,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Flexible(
              child: switch (bookmarks) {
                AsyncValue(hasValue: true, value: final items?)
                    when items.isEmpty =>
                  _BookmarksMessage(
                    icon: Icons.bookmark_add_outlined,
                    title: l10n.bookmarksEmptyTitle,
                    message: l10n.bookmarksEmptyMessage,
                  ),
                AsyncValue(hasValue: true, value: final items?) =>
                  ListView.separated(
                    padding: const EdgeInsets.only(bottom: Space.lg),
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: semantics.hairline, height: 1),
                    itemBuilder: (context, index) => _BookmarkRow(
                      bookmark: items[index],
                      characterCount: characterCount,
                      onTap: () => onJump(items[index]),
                      onDelete: () => _delete(context, ref, items[index]),
                    ),
                  ),
                AsyncValue(hasError: true) => _BookmarksMessage(
                  icon: Icons.cloud_off_rounded,
                  title: l10n.bookmarksLoadError,
                  message: l10n.connectionHint,
                  retryLabel: l10n.retry,
                  onRetry: () => ref.invalidate(bookmarksProvider(bookId)),
                ),
                _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: Space.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Bookmark bookmark,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(readerControllerProvider);

    await controller.deleteBookmark(bookId, bookmark.id);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.bookmarkDeleted),
          action: SnackBarAction(
            label: l10n.undo,
            // The API has no restore endpoint, so undo re-creates the bookmark
            // at the same anchor with the same label — indistinguishable to the
            // reader, and honest about what the backend supports.
            onPressed: () => controller.addBookmark(
              bookId,
              anchor: bookmark.anchor,
              label: bookmark.label,
            ),
          ),
        ),
      );
  }
}

class _BookmarkRow extends StatelessWidget {
  const _BookmarkRow({
    required this.bookmark,
    required this.characterCount,
    required this.onTap,
    required this.onDelete,
  });

  final Bookmark bookmark;
  final int characterCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    final label = bookmark.label?.trim();
    final hasExcerpt = label != null && label.isNotEmpty;
    final anchor = int.tryParse(bookmark.anchor) ?? 0;
    final percent = characterCount <= 0
        ? 0
        : ((anchor / characterCount) * 100).clamp(0, 100).round();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: Space.xs),
      onTap: onTap,
      leading: Icon(
        hasExcerpt ? Icons.auto_awesome_rounded : Icons.bookmark_rounded,
        size: 20,
        color: hasExcerpt ? semantics.accent : semantics.inkFaint,
      ),
      title: Text(
        hasExcerpt ? '“$label”' : l10n.bookmarkAt(percent),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: hasExcerpt ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      subtitle: hasExcerpt ? Text(l10n.bookmarkAt(percent)) : null,
      trailing: IconButton(
        tooltip: l10n.delete,
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
        onPressed: onDelete,
      ),
    );
  }
}

class _BookmarksMessage extends StatelessWidget {
  const _BookmarksMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.retryLabel,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: semantics.inkFaint),
          const SizedBox(height: Space.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: Space.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: semantics.inkMuted,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: Space.base),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(retryLabel ?? message),
            ),
          ],
        ],
      ),
    );
  }
}
