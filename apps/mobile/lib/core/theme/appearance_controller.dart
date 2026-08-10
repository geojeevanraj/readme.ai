import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/preferences_service.dart';
import 'reading_palette.dart';

/// Owns the app's appearance, expressed as a [ReadingTheme].
///
/// There is deliberately one appearance control in the product rather than a
/// "dark mode" switch plus a separate reading theme: two switches that both
/// change the page's brightness is a maze. Paper and Sepia run the app in
/// light mode, Night runs it in dark mode.
class AppearanceController extends Notifier<ReadingTheme> {
  @override
  ReadingTheme build() {
    final stored = ref
        .read(preferencesProvider)
        .readString(PreferenceKeys.readingTheme);
    return ReadingTheme.fromId(stored);
  }

  /// Select a reading theme and remember it for the next launch.
  void select(ReadingTheme theme) {
    if (state == theme) return;
    state = theme;
    ref
        .read(preferencesProvider)
        .writeString(PreferenceKeys.readingTheme, theme.id);
  }
}

/// The reader's chosen appearance.
final appearanceProvider = NotifierProvider<AppearanceController, ReadingTheme>(
  AppearanceController.new,
);

/// The app-wide [ThemeMode] implied by the chosen appearance.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appearanceProvider).themeMode;
});

/// The colours of the reading surface for the chosen appearance.
final readingPaletteProvider = Provider<ReadingPalette>((ref) {
  return ReadingPalette.of(ref.watch(appearanceProvider));
});
