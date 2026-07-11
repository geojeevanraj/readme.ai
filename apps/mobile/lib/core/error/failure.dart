import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// A typed, exhaustive description of why an operation failed.
///
/// Domain and data layers return or surface a [Failure] rather than throwing
/// across boundaries, so the presentation layer can handle every case
/// explicitly via pattern matching.
@freezed
sealed class Failure with _$Failure {
  /// The request could not reach the server (timeout, no connectivity).
  const factory Failure.network({required String message}) = NetworkFailure;

  /// The server rejected the request with a client/server status code.
  const factory Failure.server({required String message, int? statusCode}) =
      ServerFailure;

  /// The request was cancelled before completing.
  const factory Failure.cancelled({required String message}) = CancelledFailure;

  /// An unanticipated error occurred.
  const factory Failure.unexpected({required String message}) =
      UnexpectedFailure;
}
