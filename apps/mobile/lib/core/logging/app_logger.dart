import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Severity levels, aligned with `dart:developer` log level conventions.
enum LogLevel {
  debug(500),
  info(800),
  warning(900),
  error(1000);

  const LogLevel(this.value);

  /// Numeric level passed to the underlying logging sink.
  final int value;
}

/// Thin logging facade for the client.
///
/// Centralises logging so the sink can be swapped (e.g. for a remote collector)
/// without touching call sites. Uses `dart:developer` rather than `print` so
/// output integrates with tooling and respects the `avoid_print` lint.
class AppLogger {
  const AppLogger({this.name = 'readme_ai'});

  /// Logger channel name surfaced in tooling.
  final String name;

  /// Log a developer-facing diagnostic message.
  void debug(String message) => _log(message, LogLevel.debug);

  /// Log an informational message about normal operation.
  void info(String message) => _log(message, LogLevel.info);

  /// Log a recoverable problem that warrants attention.
  void warning(String message) => _log(message, LogLevel.warning);

  /// Log an error, optionally with the originating [error] and [stackTrace].
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(message, LogLevel.error, error: error, stackTrace: stackTrace);
  }

  void _log(
    String message,
    LogLevel level, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: level.value,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Provides the shared [AppLogger] instance.
final loggerProvider = Provider<AppLogger>((ref) => const AppLogger());
