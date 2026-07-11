import 'package:json_annotation/json_annotation.dart';

import '../domain/book_content.dart';
import '../domain/bookmark.dart';
import '../domain/content_format.dart';
import '../domain/reading_progress.dart';

part 'reader_dtos.g.dart';

/// Wire representation of readable book content.
@JsonSerializable(createToJson: false)
class BookContentDto {
  const BookContentDto({
    required this.bookId,
    required this.title,
    required this.format,
    required this.characterCount,
    this.content,
  });

  factory BookContentDto.fromJson(Map<String, dynamic> json) =>
      _$BookContentDtoFromJson(json);

  @JsonKey(name: 'book_id')
  final String bookId;
  final String title;
  final String format;
  @JsonKey(name: 'character_count')
  final int characterCount;
  final String? content;

  BookContent toDomain() => BookContent(
    bookId: bookId,
    title: title,
    format: ContentFormat.fromApi(format),
    characterCount: characterCount,
    text: content,
  );
}

/// Wire representation of reading progress.
@JsonSerializable(createToJson: false)
class ReadingProgressDto {
  const ReadingProgressDto({
    required this.currentPosition,
    required this.progressPercentage,
    required this.totalReadingTimeSeconds,
  });

  factory ReadingProgressDto.fromJson(Map<String, dynamic> json) =>
      _$ReadingProgressDtoFromJson(json);

  @JsonKey(name: 'current_position')
  final String currentPosition;
  @JsonKey(name: 'progress_percentage')
  final double progressPercentage;
  @JsonKey(name: 'total_reading_time_seconds')
  final int totalReadingTimeSeconds;

  ReadingProgress toDomain() => ReadingProgress(
    currentPosition: currentPosition,
    progressPercentage: progressPercentage,
    totalReadingTimeSeconds: totalReadingTimeSeconds,
  );
}

/// Wire representation of a bookmark.
@JsonSerializable(createToJson: false)
class BookmarkDto {
  const BookmarkDto({
    required this.id,
    required this.anchor,
    required this.createdAt,
    this.label,
  });

  factory BookmarkDto.fromJson(Map<String, dynamic> json) =>
      _$BookmarkDtoFromJson(json);

  final String id;
  final String anchor;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String? label;

  Bookmark toDomain() =>
      Bookmark(id: id, anchor: anchor, createdAt: createdAt, label: label);
}
