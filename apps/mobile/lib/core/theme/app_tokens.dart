import 'package:flutter/material.dart';

/// Primitive design tokens for ReadMe.ai.
///
/// Every spacing, radius, duration and curve used in the UI resolves to one of
/// these constants. Ad-hoc numeric literals in widgets are a bug: they are how
/// a design system drifts.
abstract final class Space {
  /// 2 — hairline nudges only.
  static const double xxs = 2;

  /// 4 — icon/label gaps.
  static const double xs = 4;

  /// 8 — tight grouping inside a component.
  static const double sm = 8;

  /// 12 — related elements.
  static const double md = 12;

  /// 16 — default gutter and body rhythm.
  static const double base = 16;

  /// 20 — screen edge padding on phones.
  static const double lg = 20;

  /// 24 — separation between groups.
  static const double xl = 24;

  /// 32 — section breaks.
  static const double xxl = 32;

  /// 40 — major section breaks.
  static const double xxxl = 40;

  /// 56 — hero spacing.
  static const double huge = 56;
}

/// Corner radii. One consistent language: soft-but-not-round.
abstract final class Radii {
  /// 8 — chips, badges, small controls.
  static const double sm = 8;

  /// 12 — buttons, inputs, list rows.
  static const double md = 12;

  /// 16 — cards, control groups.
  static const double lg = 16;

  /// 20 — large cards, dialogs.
  static const double xl = 20;

  /// 28 — bottom sheets (top corners only).
  static const double xxl = 28;

  /// Fully rounded (pills, avatars).
  static const double pill = 999;

  static BorderRadius all(double radius) => BorderRadius.circular(radius);

  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );
}

/// Motion tokens.
///
/// Principle: motion explains a spatial relationship or a state change, and
/// nothing else. Chrome fades, sheets rise, content never bounces.
abstract final class Motion {
  /// 120ms — immediate feedback (selection, toggles).
  static const Duration fast = Duration(milliseconds: 120);

  /// 200ms — chrome show/hide, cross-fades.
  static const Duration base = Duration(milliseconds: 200);

  /// 320ms — sheets, page transitions, scroll-to-position.
  static const Duration slow = Duration(milliseconds: 320);

  /// Default easing: decelerate, no overshoot.
  static const Curve standard = Curves.easeOutCubic;

  /// Emphasised entrances (sheets, first paint).
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  /// Honour the OS "reduce motion" setting: returns [Duration.zero] when the
  /// user has asked for fewer animations.
  static Duration of(BuildContext context, Duration duration) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? Duration.zero
        : duration;
  }
}

/// Elevation is expressed as a single soft shadow, used only for surfaces that
/// float above content (bottom bars, sheets, FABs). Reading surfaces never
/// carry a shadow — paper does not hover.
abstract final class Shadows {
  static List<BoxShadow> floating(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Typographic measure for long-form reading.
///
/// Line length is the single biggest lever on reading comfort: 60–70 characters
/// is the target, so the maximum text width scales with the chosen font size
/// instead of being a fixed pixel value.
abstract final class Measure {
  static const double minWidth = 320;
  static const double maxWidth = 680;

  /// Width at which a layout stops being a phone layout.
  ///
  /// Beyond this the UI gains breathing room rather than line length: a list
  /// row stretched across a desktop window is harder to scan, not easier.
  static const double wideBreakpoint = 720;

  /// Maximum width for list and detail content on large viewports.
  static const double contentMaxWidth = 760;

  /// Ideal column width for [fontSize] (~64 characters at ~0.5em per glyph).
  static double forFontSize(double fontSize) =>
      (fontSize * 32).clamp(minWidth, maxWidth);
}

/// Minimum interactive target, per WCAG 2.5.5 / platform guidance.
abstract final class Touch {
  static const double minTarget = 48;
  static const Size minSize = Size(minTarget, minTarget);
}
