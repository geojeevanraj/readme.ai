import 'package:json_annotation/json_annotation.dart';

import '../domain/explanation.dart';
import '../domain/prerequisite.dart';
import '../domain/selection_type.dart';

part 'explanation_dto.g.dart';

/// Wire representation of a prerequisite concept.
@JsonSerializable(createToJson: false)
class PrerequisiteDto {
  const PrerequisiteDto({required this.name, required this.reason});

  factory PrerequisiteDto.fromJson(Map<String, dynamic> json) =>
      _$PrerequisiteDtoFromJson(json);

  final String name;
  final String reason;

  Prerequisite toDomain() => Prerequisite(name: name, reason: reason);
}

/// Wire representation of a unified explanation.
@JsonSerializable(createToJson: false)
class ExplanationDto {
  const ExplanationDto({
    required this.selectionType,
    required this.explanation,
    this.meaning,
    this.example,
    this.prerequisites = const [],
  });

  factory ExplanationDto.fromJson(Map<String, dynamic> json) =>
      _$ExplanationDtoFromJson(json);

  @JsonKey(name: 'selection_type')
  final String selectionType;
  final String explanation;
  final String? meaning;
  final String? example;
  @JsonKey(defaultValue: <PrerequisiteDto>[])
  final List<PrerequisiteDto> prerequisites;

  Explanation toDomain() => Explanation(
    selectionType: SelectionType.fromApi(selectionType),
    explanation: explanation,
    meaning: meaning,
    example: example,
    prerequisites: prerequisites.map((dto) => dto.toDomain()).toList(),
  );
}
