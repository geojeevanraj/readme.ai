import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/preferences/preferences_service.dart';
import 'core/state/retry_policy.dart';

/// Application entry point.
///
/// Initialises Firebase/Google Sign-In and loads user preferences, then wraps
/// the app in a [ProviderScope] so Riverpod serves as both the state container
/// and the dependency-injection root. If Firebase configuration is absent the
/// app still starts (landing on the login screen); sign-in then reports the
/// missing configuration rather than crashing at launch.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // In development mode Firebase is bypassed entirely (mock auth).
  if (!AppConfig.fromEnvironment().devAuth) {
    try {
      await FirebaseBootstrap.ensureInitialized();
    } on Object catch (error) {
      debugPrint('Firebase initialisation skipped: $error');
    }
  }

  // Preferences are read synchronously everywhere else, so they are loaded
  // once here — before the first frame — and injected as an override.
  final preferences = await PreferencesService.load();

  runApp(
    ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(preferences)],
      retry: noAutomaticRetry,
      child: const ReadMeApp(),
    ),
  );
}
