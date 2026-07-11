import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the user's selected [ThemeMode] (light, dark, or system).
///
/// Defaults to [ThemeMode.system]. Persistence across launches is intentionally
/// deferred to the Settings feature in a later sprint.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Replace the current theme mode.
  void setMode(ThemeMode mode) => state = mode;

  /// Toggle between light and dark, treating `system` as a starting point.
  void toggle() {
    state = switch (state) {
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.system => ThemeMode.dark,
    };
  }
}

/// Exposes the [ThemeModeController] and its current [ThemeMode] value.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
