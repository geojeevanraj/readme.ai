import 'package:flutter/material.dart';

/// Typography for ReadMe.ai: a serif for prose, the platform sans for chrome.
///
/// The reading face is resolved from fonts that ship with iOS and Android
/// rather than a bundled or network-fetched webfont, so a reader never waits on
/// the network to see a page of text and the app adds no font payload. The
/// fallback chain degrades gracefully: Georgia (both platforms) → Iowan Old
/// Style/Charter/Palatino (iOS) → Noto Serif/`serif` (Android).
///
/// If the product later wants a signature face (Literata, Source Serif), drop
/// the `.ttf` files into `assets/fonts/`, declare them in `pubspec.yaml`, and
/// change [serifFamily] — nothing else needs to move.
abstract final class AppTypography {
  /// Reading serif.
  static const String serifFamily = 'Georgia';

  static const List<String> serifFallback = <String>[
    'Iowan Old Style',
    'Charter',
    'Palatino',
    'Times New Roman',
    'Noto Serif',
    'serif',
  ];

  /// Reading sans — the platform UI face (SF Pro / Roboto), which is what
  /// `null` resolves to.
  static const List<String> sansFallback = <String>[
    'SF Pro Text',
    'Roboto',
    'Helvetica Neue',
    'sans-serif',
  ];

  /// Monospace, for file names and code-like metadata.
  static const String monoFamily = 'Menlo';

  static const List<String> monoFallback = <String>[
    'SF Mono',
    'Roboto Mono',
    'Courier New',
    'monospace',
  ];

  /// The UI type scale.
  ///
  /// Sizes are fixed and deliberate; hierarchy comes from weight and colour,
  /// not from a dozen near-identical sizes. Reading text is *not* defined here
  /// — the reader owns its own size because the user controls it.
  static TextTheme uiTextTheme(TextTheme base, Color onSurface) {
    return base
        .copyWith(
          // Marketing / empty-state headline.
          displaySmall: const TextStyle(
            fontSize: 34,
            height: 1.14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
          // Screen titles.
          headlineMedium: const TextStyle(
            fontSize: 26,
            height: 1.20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineSmall: const TextStyle(
            fontSize: 21,
            height: 1.24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          // Card titles, sheet titles.
          titleLarge: const TextStyle(
            fontSize: 18,
            height: 1.28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            height: 1.32,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          titleSmall: const TextStyle(
            fontSize: 14,
            height: 1.36,
            fontWeight: FontWeight.w600,
          ),
          // UI body.
          bodyLarge: const TextStyle(fontSize: 16, height: 1.50),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.46),
          bodySmall: const TextStyle(fontSize: 13, height: 1.42),
          // Buttons and inline labels.
          labelLarge: const TextStyle(
            fontSize: 15,
            height: 1.20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          labelMedium: const TextStyle(
            fontSize: 13,
            height: 1.20,
            fontWeight: FontWeight.w600,
          ),
          // Meta text: uppercase, tracked, small — used sparingly.
          labelSmall: const TextStyle(
            fontSize: 11,
            height: 1.20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        )
        .apply(
          bodyColor: onSurface,
          displayColor: onSurface,
          fontFamilyFallback: sansFallback,
        );
  }

  /// Base style for reading prose at [fontSize] with [lineHeight].
  static TextStyle reading({
    required double fontSize,
    required double lineHeight,
    required Color color,
    required bool serif,
  }) {
    return TextStyle(
      fontFamily: serif ? serifFamily : null,
      fontFamilyFallback: serif ? serifFallback : sansFallback,
      fontSize: fontSize,
      height: lineHeight,
      color: color,
      letterSpacing: serif ? 0 : 0.1,
      // Slightly heavier than hairline for dark surfaces is handled by the
      // caller choosing the right ink colour; weight stays regular for prose.
      fontWeight: FontWeight.w400,
    );
  }

  /// Style for file names, sizes and other machine-ish metadata.
  static TextStyle mono(TextStyle? base) {
    return (base ?? const TextStyle()).copyWith(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      letterSpacing: 0,
    );
  }
}
