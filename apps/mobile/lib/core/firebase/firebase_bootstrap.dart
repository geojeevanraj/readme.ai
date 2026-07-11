import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Initialises Firebase and Google Sign-In before the app runs.
///
/// Configuration is supplied at build time via `--dart-define` rather than a
/// committed `firebase_options.dart`, so no credentials live in the repository
/// and each environment is configured independently. See the mobile README for
/// the required defines.
abstract final class FirebaseBootstrap {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  // Optional OAuth client ids for Google Sign-In (platform dependent).
  static const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Whether the minimum Firebase configuration has been provided.
  static bool get isConfigured => _apiKey.isNotEmpty && _projectId.isNotEmpty;

  /// Initialise Firebase and Google Sign-In. Safe to call exactly once at
  /// startup. Throws [StateError] if configuration is missing.
  static Future<void> ensureInitialized() async {
    if (!isConfigured) {
      throw StateError(
        'Firebase is not configured. Provide the FIREBASE_* --dart-define '
        'values (see apps/mobile/README.md).',
      );
    }

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _emptyToNull(_authDomain),
        storageBucket: _emptyToNull(_storageBucket),
      ),
    );

    await GoogleSignIn.instance.initialize(
      clientId: _emptyToNull(_googleClientId),
      serverClientId: _emptyToNull(_googleServerClientId),
    );
  }

  static String? _emptyToNull(String value) => value.isEmpty ? null : value;
}
