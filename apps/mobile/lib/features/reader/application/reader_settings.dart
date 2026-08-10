import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_settings.freezed.dart';

/// The reading face. A serif is the default because it is what long-form
/// reading is set in almost everywhere it is done well; a sans option exists
/// because some readers (and some dyslexic readers in particular) prefer it.
enum ReaderTypeface {
  serif,
  sans;

  String get id => name;

  static ReaderTypeface fromId(String? id) {
    return ReaderTypeface.values.firstWhere(
      (typeface) => typeface.id == id,
      orElse: () => ReaderTypeface.serif,
    );
  }

  bool get isSerif => this == ReaderTypeface.serif;
}

/// Typography preferences for the reader, persisted across launches.
@freezed
abstract class ReaderSettings with _$ReaderSettings {
  const factory ReaderSettings({
    @Default(19.0) double fontSize,
    @Default(1.6) double lineHeight,
    @Default(ReaderTypeface.serif) ReaderTypeface typeface,
  }) = _ReaderSettings;

  const ReaderSettings._();

  /// Bounds keep typography legible.
  static const double minFontSize = 14.0;
  static const double maxFontSize = 30.0;
  static const double minLineHeight = 1.3;
  static const double maxLineHeight = 2.1;

  /// Discrete steps, so the control has detents the reader can feel and the
  /// value never lands on something like 18.399999.
  static const List<double> fontSizeSteps = [14, 16, 17, 19, 21, 24, 27, 30];
  static const List<double> lineHeightSteps = [1.3, 1.45, 1.6, 1.8, 2.1];

  /// Position of [fontSize] in [fontSizeSteps] (nearest step).
  int get fontSizeIndex => _nearestIndex(fontSizeSteps, fontSize);

  /// Position of [lineHeight] in [lineHeightSteps] (nearest step).
  int get lineHeightIndex => _nearestIndex(lineHeightSteps, lineHeight);

  static int _nearestIndex(List<double> steps, double value) {
    var best = 0;
    var bestDelta = (steps.first - value).abs();
    for (var index = 1; index < steps.length; index++) {
      final delta = (steps[index] - value).abs();
      if (delta < bestDelta) {
        best = index;
        bestDelta = delta;
      }
    }
    return best;
  }
}
