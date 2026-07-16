import 'package:freezed_annotation/freezed_annotation.dart';

import 'prerequisite.dart';
import 'selection_type.dart';

part 'explanation.freezed.dart';

/// A unified explanation of a selection (word, sentence, or paragraph).
///
/// [meaning] and [example] are populated only for word selections.
/// [prerequisites] are decided by the Learning Intelligence Engine and may be
/// empty.
@freezed
abstract class Explanation with _$Explanation {
  const factory Explanation({
    required SelectionType selectionType,
    required String explanation,
    String? meaning,
    String? example,
    @Default(<Prerequisite>[]) List<Prerequisite> prerequisites,
  }) = _Explanation;
}
