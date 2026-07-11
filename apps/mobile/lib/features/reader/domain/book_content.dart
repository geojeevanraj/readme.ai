import 'package:freezed_annotation/freezed_annotation.dart';

import 'content_format.dart';

part 'book_content.freezed.dart';

/// Readable content of a book (domain representation).
@freezed
abstract class BookContent with _$BookContent {
  const factory BookContent({
    required String bookId,
    required String title,
    required ContentFormat format,
    required int characterCount,
    String? text,
  }) = _BookContent;
}
