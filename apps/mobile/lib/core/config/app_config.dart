import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_environment.dart';

part 'app_config.freezed.dart';

/// Immutable, environment-derived application configuration.
///
/// Values are injected at build time with `--dart-define` so the same binary
/// can target different environments without code changes.
@freezed
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    required AppEnvironment environment,
    required String apiBaseUrl,
    @Default(false) bool devAuth,
  }) = _AppConfig;

  const AppConfig._();

  /// Build configuration from compile-time `--dart-define` values.
  factory AppConfig.fromEnvironment() {
    const envName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    );
    // Development-only: bypass Firebase and auto-login a mock user.
    // NEVER enable in production builds.
    const devAuth = bool.fromEnvironment('DEV_AUTH');
    return AppConfig(
      environment: AppEnvironment.fromName(envName),
      apiBaseUrl: apiBaseUrl,
      devAuth: devAuth,
    );
  }
}

/// Exposes the resolved [AppConfig] to the widget/provider tree.
///
/// Overridden in tests to inject deterministic configuration.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
