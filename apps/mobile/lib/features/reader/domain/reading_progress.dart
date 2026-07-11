import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_progress.freezed.dart';

/// A user's saved reading position within a book.
@freezed
abstract class ReadingProgress with _$ReadingProgress {
  const factory ReadingProgress({
    required String currentPosition,
    required double progressPercentage,
    required int totalReadingTimeSeconds,
  }) = _ReadingProgress;
}
