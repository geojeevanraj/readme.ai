import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The reader's appearance, chosen by the reader and persisted.
///
/// This is the *only* light/dark control in the app: picking [night] also puts
/// the rest of the app into dark mode, so the reader never has to reason about
/// two competing switches.
enum ReadingTheme {
  /// Warm white paper.
  paper,

  /// Low-blue sepia, for evening reading in a lit room.
  sepia,

  /// True dark, for reading in the dark.
  night;

  /// Storage key value — stable across releases.
  String get id => name;

  static ReadingTheme fromId(String? id) {
    return ReadingTheme.values.firstWhere(
      (theme) => theme.id == id,
      orElse: () => ReadingTheme.paper,
    );
  }

  /// The app-wide [ThemeMode] implied by this reading theme.
  ThemeMode get themeMode =>
      this == ReadingTheme.night ? ThemeMode.dark : ThemeMode.light;

  bool get isDark => this == ReadingTheme.night;
}

/// Colours for the reading surface itself.
///
/// Kept separate from [ColorScheme] because the reading canvas is intentionally
/// warmer and lower-contrast than app chrome.
@immutable
class ReadingPalette {
  const ReadingPalette({
    required this.canvas,
    required this.ink,
    required this.inkMuted,
    required this.hairline,
    required this.selection,
  });

  final Color canvas;
  final Color ink;
  final Color inkMuted;
  final Color hairline;

  /// Text-selection tint used while choosing something to explain.
  final Color selection;

  static const ReadingPalette paper = ReadingPalette(
    canvas: AppColors.paper,
    ink: AppColors.ink,
    inkMuted: AppColors.inkMuted,
    hairline: AppColors.hairline,
    selection: Color(0x333B4CE0),
  );

  static const ReadingPalette sepia = ReadingPalette(
    canvas: AppColors.sepia,
    ink: AppColors.sepiaInk,
    inkMuted: AppColors.sepiaInkMuted,
    hairline: AppColors.sepiaHairline,
    selection: Color(0x40A9741C),
  );

  static const ReadingPalette night = ReadingPalette(
    canvas: AppColors.inkCanvas,
    ink: AppColors.inkOn,
    inkMuted: AppColors.inkOnMuted,
    hairline: AppColors.inkHairline,
    selection: Color(0x4DAFB8FF),
  );

  static ReadingPalette of(ReadingTheme theme) => switch (theme) {
    ReadingTheme.paper => paper,
    ReadingTheme.sepia => sepia,
    ReadingTheme.night => night,
  };
}
