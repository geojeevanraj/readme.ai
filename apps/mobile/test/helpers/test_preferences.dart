import 'package:readme_ai/core/preferences/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build an in-memory [PreferencesService] for widget tests.
///
/// Pass [values] to simulate a returning reader (e.g. stored typography, or a
/// coach mark that has already been dismissed).
Future<PreferencesService> testPreferences([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return PreferencesService.load();
}
