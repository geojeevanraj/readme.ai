/// The runtime environment the client is built for.
///
/// Selected at build time via `--dart-define=APP_ENV=...`. Defaults to
/// [AppEnvironment.development] when unspecified.
enum AppEnvironment {
  development,
  staging,
  production;

  /// Resolve an [AppEnvironment] from its string name, defaulting to
  /// [AppEnvironment.development] for unknown or empty values.
  static AppEnvironment fromName(String name) {
    return AppEnvironment.values.firstWhere(
      (env) => env.name == name,
      orElse: () => AppEnvironment.development,
    );
  }

  /// Whether this is a production build.
  bool get isProduction => this == AppEnvironment.production;
}
