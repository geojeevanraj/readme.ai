import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reader_controller.dart';
import '../../application/reader_providers.dart';
import '../../domain/bookmark.dart';

/// Bottom sheet listing the book's bookmarks, with jump and delete.
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
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bookmarks', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Flexible(
                child: bookmarks.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, _) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text("Couldn't load bookmarks."),
                  ),
                  data: (items) => items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No bookmarks yet.'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final bookmark = items[index];
                            return ListTile(
                              leading: const Icon(Icons.bookmark_outline),
                              title: Text(
                                bookmark.label ?? 'Bookmark',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => onJump(bookmark),
                              trailing: IconButton(
                                tooltip: 'Delete bookmark',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => ref
                                    .read(readerControllerProvider)
                                    .deleteBookmark(bookId, bookmark.id),
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
