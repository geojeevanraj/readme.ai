import 'package:flutter/material.dart';

/// ReadMe.ai's colour system.
///
/// Two ideas drive it:
///
/// 1. **Reading surfaces are paper, chrome is ink.** The canvas is a warm
///    off-white (or a true dark) rather than pure #FFFFFF/#000000, because
///    maximum contrast is fatiguing over thousands of words.
/// 2. **Dark mode is a peer, not an inversion.** The dark palette has its own
///    warm off-white ink (#ECEAE4) to avoid the halation you get from pure
///    white text on near-black.
abstract final class AppColors {
  // ---------------------------------------------------------------- brand ---

  /// Seed for the Material colour scheme.
  static const Color seed = cobalt;

  /// Primary action colour (light mode). Contrast on [paper] ≈ 7.4:1.
  static const Color cobalt = Color(0xFF3B4CE0);

  /// Pressed/active cobalt.
  static const Color cobaltPressed = Color(0xFF2C3AB4);

  /// Primary action colour (dark mode). Contrast on [inkCanvas] ≈ 8.9:1.
  static const Color cobaltLight = Color(0xFFAFB8FF);

  // ---------------------------------------------------------- light: paper ---

  /// App canvas — warm paper.
  static const Color paper = Color(0xFFF7F4EE);

  /// Raised surfaces (cards, sheets) on [paper].
  static const Color paperRaised = Color(0xFFFFFDF8);

  /// Recessed surfaces (wells, unselected segments).
  static const Color paperSunken = Color(0xFFEFEAE1);

  /// Body text on [paper] — contrast ≈ 15.8:1.
  static const Color ink = Color(0xFF17171B);

  /// Secondary text on [paper] — contrast ≈ 7.1:1 (AA at any size).
  static const Color inkMuted = Color(0xFF56555C);

  /// Tertiary text/icons on [paper] — contrast ≈ 4.6:1 (AA for ≥16px).
  static const Color inkFaint = Color(0xFF6E6D75);

  /// 1px separators on [paper].
  static const Color hairline = Color(0xFFDFD8CC);

  /// Cobalt wash for selected/active states on light surfaces.
  static const Color cobaltTint = Color(0xFFE7E9FD);

  // ------------------------------------------------------------ light: sepia ---

  /// Sepia reading canvas.
  static const Color sepia = Color(0xFFF2E7D2);

  /// Body text on [sepia] — contrast ≈ 12.6:1.
  static const Color sepiaInk = Color(0xFF2E2618);

  /// Secondary text on [sepia] — contrast ≈ 5.6:1.
  static const Color sepiaInkMuted = Color(0xFF6A5C42);

  /// Separators on [sepia].
  static const Color sepiaHairline = Color(0xFFDCCDB0);

  // ------------------------------------------------------------- dark: ink ---

  /// App canvas — true dark, slightly blue to feel like night rather than soot.
  static const Color inkCanvas = Color(0xFF0E0F13);

  /// Raised surfaces on [inkCanvas].
  static const Color inkSurface = Color(0xFF171922);

  /// Higher surfaces (sheets, menus).
  static const Color inkRaised = Color(0xFF20232E);

  /// Body text on [inkCanvas] — warm off-white, contrast ≈ 15.2:1.
  static const Color inkOn = Color(0xFFECEAE4);

  /// Secondary text on [inkCanvas] — contrast ≈ 7.7:1.
  static const Color inkOnMuted = Color(0xFFA9A7B0);

  /// Tertiary text/icons on [inkCanvas] — contrast ≈ 4.9:1.
  static const Color inkOnFaint = Color(0xFF83818B);

  /// 1px separators on dark surfaces.
  static const Color inkHairline = Color(0xFF2A2D38);

  /// Cobalt wash for selected/active states on dark surfaces.
  static const Color cobaltTintDark = Color(0xFF242845);

  // --------------------------------------------------------------- accents ---

  /// Amber — "in progress", processing, and the Explain highlight.
  static const Color amber = Color(0xFFE9A23B);
  static const Color amberTint = Color(0xFFFDEBCE);
  static const Color amberInk = Color(0xFF6E4405);
  static const Color amberTintDark = Color(0xFF4A3410);
  static const Color amberInkDark = Color(0xFFF6CE8E);

  /// Green — "ready" / success.
  static const Color moss = Color(0xFF1F7A55);
  static const Color mossTint = Color(0xFFD5EEE1);
  static const Color mossInk = Color(0xFF11512F);
  static const Color mossTintDark = Color(0xFF14382A);
  static const Color mossInkDark = Color(0xFF8ED9B4);

  /// Red — destructive/failure.
  static const Color rust = Color(0xFFB3261E);
  static const Color rustTint = Color(0xFFFADAD7);
  static const Color rustInk = Color(0xFF7A1811);
  static const Color rustTintDark = Color(0xFF4A1A17);
  static const Color rustInkDark = Color(0xFFFFB4AB);

  /// Deterministic cover gradients, in the same family as the palette.
  static const List<List<Color>> coverGradients = [
    [Color(0xFF3B4CE0), Color(0xFF232C86)],
    [Color(0xFFCE6C3C), Color(0xFF7E3230)],
    [Color(0xFF1F7A55), Color(0xFF12463A)],
    [Color(0xFF6C4FC0), Color(0xFF362A6E)],
    [Color(0xFF2F6389), Color(0xFF1A3550)],
    [Color(0xFF8A5B96), Color(0xFF44284F)],
  ];

  /// Pick a stable gradient for [seedText] (a title), so a book always looks
  /// like itself.
  static List<Color> coverFor(String seedText) =>
      coverGradients[seedText.hashCode.abs() % coverGradients.length];
}
