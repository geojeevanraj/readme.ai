import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_settings.freezed.dart';

/// Display preferences for the reader. Held in memory for the session.
@freezed
abstract class ReaderSettings with _$ReaderSettings {
  const factory ReaderSettings({
    @Default(18.0) double fontSize,
    @Default(1.6) double lineHeight,
  }) = _ReaderSettings;

  const ReaderSettings._();

  /// Bounds keep typography legible.
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;
  static const double minLineHeight = 1.2;
  static const double maxLineHeight = 2.4;
}
