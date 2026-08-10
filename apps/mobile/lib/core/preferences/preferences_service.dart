import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper over [SharedPreferences] for user preferences.
///
/// Preferences are loaded once during startup so every read is synchronous:
/// the reader's typography must be correct on the first frame, not after an
/// async gap that would repaint the page under the reader's eyes.
class PreferencesService {
  const PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  /// Load the backing store. Called once from `main()`.
  static Future<PreferencesService> load() async {
    return PreferencesService(await SharedPreferences.getInstance());
  }

  double? readDouble(String key) => _prefs.getDouble(key);

  String? readString(String key) => _prefs.getString(key);

  bool? readBool(String key) => _prefs.getBool(key);

  /// Writes are fire-and-forget: a failed preference write must never block or
  /// break the reading session.
  void writeDouble(String key, double value) {
    _prefs.setDouble(key, value).ignore();
  }

  void writeString(String key, String value) {
    _prefs.setString(key, value).ignore();
  }

  void writeBool(String key, {required bool value}) {
    _prefs.setBool(key, value).ignore();
  }
}

/// Provides the loaded [PreferencesService].
///
/// Overridden in `main()` (and in tests with an in-memory instance); reading it
/// without an override is a programming error, so it throws loudly.
final preferencesProvider = Provider<PreferencesService>((ref) {
  throw StateError(
    'preferencesProvider was not overridden. Override it in main() with the '
    'result of PreferencesService.load().',
  );
});

/// Keys for persisted preferences. Values are stable across releases.
abstract final class PreferenceKeys {
  static const String readerFontSize = 'reader.fontSize';
  static const String readerLineHeight = 'reader.lineHeight';
  static const String readerTypeface = 'reader.typeface';
  static const String readingTheme = 'reader.theme';

  /// Whether the one-time "select text, then Explain" coach mark has been seen.
  static const String explainHintSeen = 'reader.explainHintSeen';
}
