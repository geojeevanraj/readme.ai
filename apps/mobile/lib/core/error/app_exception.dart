import 'failure.dart';

/// Exception wrapper carrying a typed [Failure].
///
/// Thrown only at infrastructure boundaries (e.g. the networking layer) where
/// raising is unavoidable; higher layers convert it back into a [Failure] for
/// explicit handling.
class AppException implements Exception {
  const AppException(this.failure);

  /// The typed failure this exception represents.
  final Failure failure;

  @override
  String toString() => 'AppException($failure)';
}
