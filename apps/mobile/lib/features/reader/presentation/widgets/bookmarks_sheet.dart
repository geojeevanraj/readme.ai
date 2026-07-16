import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reader_controller.dart';
import '../../application/reader_providers.dart';
import '../../domain/bookmark.dart';

/// Bottom sheet listing the book's saved positions.
class BookmarksSheet extends ConsumerWidget {
  const BookmarksSheet({required this.bookId, required this.onJump, super.key});

  final String bookId;
  final void Function(Bookmark) onJump;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider(bookId));
    final theme = Theme.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.bookmarks_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bookmarks', style: theme.textTheme.titleLarge),
                        Text(
                          'Saved places in this book',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close bookmarks',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: bookmarks.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, _) => const _BookmarksMessage(
                    icon: Icons.cloud_off_outlined,
                    title: "Couldn't load bookmarks.",
                    message: 'Close this sheet and try again.',
                  ),
                  data: (items) => items.isEmpty
                      ? const _BookmarksMessage(
                          icon: Icons.bookmark_add_outlined,
                          title: 'No bookmarks yet.',
                          message:
                              'Tap the bookmark icon while reading to save your place.',
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final bookmark = items[index];
                            return Material(
                              color: theme.colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.only(
                                  left: 14,
                                  right: 6,
                                  top: 5,
                                  bottom: 5,
                                ),
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    Icons.bookmark_rounded,
                                    size: 19,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                title: Text(
                                  bookmark.label ?? 'Bookmark',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: const Text('Tap to continue here'),
                                onTap: () => onJump(bookmark),
                                trailing: IconButton(
                                  tooltip: 'Delete bookmark',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => ref
                                      .read(readerControllerProvider)
                                      .deleteBookmark(bookId, bookmark.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarksMessage extends StatelessWidget {
  const _BookmarksMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
