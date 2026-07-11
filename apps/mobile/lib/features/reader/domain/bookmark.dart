import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark.freezed.dart';

/// A saved reading position, anchored by a stable position anchor.
@freezed
abstract class Bookmark with _$Bookmark {
  const factory Bookmark({
    required String id,
    required String anchor,
    required DateTime createdAt,
    String? label,
  }) = _Bookmark;
}
