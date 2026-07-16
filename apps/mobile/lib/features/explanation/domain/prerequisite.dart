import 'package:freezed_annotation/freezed_annotation.dart';

part 'prerequisite.freezed.dart';

/// A concept the reader may need to understand before the selection.
@freezed
abstract class Prerequisite with _$Prerequisite {
  const factory Prerequisite({required String name, required String reason}) =
      _Prerequisite;
}
