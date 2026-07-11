import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_exception.freezed.dart';

/// Typed, exhaustive description of an authentication failure.
///
/// Implements [Exception] so it can be thrown across the data boundary and
/// surfaced by `AsyncValue.guard` in the application layer.
@freezed
sealed class AuthException with _$AuthException implements Exception {
  const AuthException._();

  /// The user dismissed the provider's sign-in flow.
  const factory AuthException.cancelled() = AuthCancelled;

  /// Authentication is not configured (e.g. Firebase not initialised).
  const factory AuthException.notConfigured() = AuthNotConfigured;

  /// Any other failure, with a human-readable [message].
  const factory AuthException.unknown(String message) = AuthUnknown;

  /// A message suitable for display to the user.
  String get displayMessage => switch (this) {
    AuthCancelled() => 'Sign-in was cancelled.',
    AuthNotConfigured() =>
      'Authentication is not configured. See the setup guide.',
    AuthUnknown(:final message) => message,
  };

  /// Whether this failure is a user-initiated cancellation (not a real error).
  bool get isCancellation => this is AuthCancelled;
}
