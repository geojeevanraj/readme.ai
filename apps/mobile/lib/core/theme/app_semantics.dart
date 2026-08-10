import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic colour roles that Material's [ColorScheme] doesn't cover.
///
/// Widgets read these through `Theme.of(context).extension<AppSemantics>()!`
/// (or the [BuildContextSemantics] helper) instead of reaching into
/// [AppColors] directly, so a widget can never pick the light value while the
/// app is in dark mode.
@immutable
class AppSemantics extends ThemeExtension<AppSemantics> {
  const AppSemantics({
    required this.canvas,
    required this.surface,
    required this.surfaceSunken,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.hairline,
    required this.accent,
    required this.accentTint,
    required this.amber,
    required this.amberTint,
    required this.amberInk,
    required this.moss,
    required this.mossTint,
    required this.mossInk,
    required this.rust,
    required this.rustTint,
    required this.rustInk,
    required this.shadow,
    required this.explainHighlight,
  });

  /// App background.
  final Color canvas;

  /// Raised surface (cards, bars).
  final Color surface;

  /// Recessed surface (wells, unselected segments, skeletons).
  final Color surfaceSunken;

  /// Primary text.
  final Color ink;

  /// Secondary text — meets AA at all sizes.
  final Color inkMuted;

  /// Tertiary text and icons — meets AA at 16px+.
  final Color inkFaint;

  /// 1px separators and borders.
  final Color hairline;

  /// Interactive accent.
  final Color accent;

  /// Accent wash for selected states.
  final Color accentTint;

  final Color amber;
  final Color amberTint;
  final Color amberInk;

  final Color moss;
  final Color mossTint;
  final Color mossInk;

  final Color rust;
  final Color rustTint;
  final Color rustInk;

  /// Shadow colour for floating surfaces.
  final Color shadow;

  /// Wash applied to text the reader has asked the AI to explain.
  final Color explainHighlight;

  static const AppSemantics light = AppSemantics(
    canvas: AppColors.paper,
    surface: AppColors.paperRaised,
    surfaceSunken: AppColors.paperSunken,
    ink: AppColors.ink,
    inkMuted: AppColors.inkMuted,
    inkFaint: AppColors.inkFaint,
    hairline: AppColors.hairline,
    accent: AppColors.cobalt,
    accentTint: AppColors.cobaltTint,
    amber: AppColors.amber,
    amberTint: AppColors.amberTint,
    amberInk: AppColors.amberInk,
    moss: AppColors.moss,
    mossTint: AppColors.mossTint,
    mossInk: AppColors.mossInk,
    rust: AppColors.rust,
    rustTint: AppColors.rustTint,
    rustInk: AppColors.rustInk,
    shadow: AppColors.ink,
    explainHighlight: Color(0x59E9A23B),
  );

  static const AppSemantics dark = AppSemantics(
    canvas: AppColors.inkCanvas,
    surface: AppColors.inkSurface,
    surfaceSunken: AppColors.inkRaised,
    ink: AppColors.inkOn,
    inkMuted: AppColors.inkOnMuted,
    inkFaint: AppColors.inkOnFaint,
    hairline: AppColors.inkHairline,
    accent: AppColors.cobaltLight,
    accentTint: AppColors.cobaltTintDark,
    amber: AppColors.amber,
    amberTint: AppColors.amberTintDark,
    amberInk: AppColors.amberInkDark,
    moss: AppColors.moss,
    mossTint: AppColors.mossTintDark,
    mossInk: AppColors.mossInkDark,
    rust: AppColors.rust,
    rustTint: AppColors.rustTintDark,
    rustInk: AppColors.rustInkDark,
    shadow: Color(0xFF000000),
    explainHighlight: Color(0x66B57A24),
  );

  @override
  AppSemantics copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSunken,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? hairline,
    Color? accent,
    Color? accentTint,
    Color? amber,
    Color? amberTint,
    Color? amberInk,
    Color? moss,
    Color? mossTint,
    Color? mossInk,
    Color? rust,
    Color? rustTint,
    Color? rustInk,
    Color? shadow,
    Color? explainHighlight,
  }) {
    return AppSemantics(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      hairline: hairline ?? this.hairline,
      accent: accent ?? this.accent,
      accentTint: accentTint ?? this.accentTint,
      amber: amber ?? this.amber,
      amberTint: amberTint ?? this.amberTint,
      amberInk: amberInk ?? this.amberInk,
      moss: moss ?? this.moss,
      mossTint: mossTint ?? this.mossTint,
      mossInk: mossInk ?? this.mossInk,
      rust: rust ?? this.rust,
      rustTint: rustTint ?? this.rustTint,
      rustInk: rustInk ?? this.rustInk,
      shadow: shadow ?? this.shadow,
      explainHighlight: explainHighlight ?? this.explainHighlight,
    );
  }

  @override
  AppSemantics lerp(ThemeExtension<AppSemantics>? other, double t) {
    if (other is! AppSemantics) return this;
    return AppSemantics(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberTint: Color.lerp(amberTint, other.amberTint, t)!,
      amberInk: Color.lerp(amberInk, other.amberInk, t)!,
      moss: Color.lerp(moss, other.moss, t)!,
      mossTint: Color.lerp(mossTint, other.mossTint, t)!,
      mossInk: Color.lerp(mossInk, other.mossInk, t)!,
      rust: Color.lerp(rust, other.rust, t)!,
      rustTint: Color.lerp(rustTint, other.rustTint, t)!,
      rustInk: Color.lerp(rustInk, other.rustInk, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      explainHighlight: Color.lerp(
        explainHighlight,
        other.explainHighlight,
        t,
      )!,
    );
  }
}

/// Ergonomic access to the semantic palette.
extension BuildContextSemantics on BuildContext {
  /// The semantic colour roles for the current theme.
  AppSemantics get semantics =>
      Theme.of(this).extension<AppSemantics>() ?? AppSemantics.light;
}
