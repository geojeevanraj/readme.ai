// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_semantics.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Global visual language for ReadMe.ai.
///
/// Component language, applied consistently: flat surfaces, one hairline
/// border, no gradients or shadows on content, [Radii.md]–[Radii.lg] corners,
/// and 48dp minimum touch targets.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final semantics = isDark ? AppSemantics.dark : AppSemantics.light;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: brightness,
        ).copyWith(
          primary: semantics.accent,
          onPrimary: isDark ? AppColors.ink : Colors.white,
          primaryContainer: semantics.accentTint,
          onPrimaryContainer: isDark
              ? AppColors.inkOn
              : AppColors.cobaltPressed,
          secondary: semantics.amberInk,
          onSecondary: isDark ? AppColors.ink : Colors.white,
          secondaryContainer: semantics.amberTint,
          onSecondaryContainer: semantics.amberInk,
          tertiary: semantics.mossInk,
          tertiaryContainer: semantics.mossTint,
          onTertiaryContainer: semantics.mossInk,
          surface: semantics.surface,
          onSurface: semantics.ink,
          onSurfaceVariant: semantics.inkMuted,
          surfaceContainerLowest: semantics.canvas,
          surfaceContainerHighest: semantics.surfaceSunken,
          outline: semantics.inkFaint,
          outlineVariant: semantics.hairline,
          error: semantics.rust,
          onError: Colors.white,
          errorContainer: semantics.rustTint,
          onErrorContainer: semantics.rustInk,
          shadow: semantics.shadow,
        );

    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = AppTypography.uiTextTheme(base.textTheme, semantics.ink);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[semantics],
      scaffoldBackgroundColor: semantics.canvas,
      canvasColor: semantics.canvas,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      // Chrome is quiet: no elevation, no tint, no centred titles.
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: semantics.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: semantics.ink,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: semantics.ink),
        iconTheme: IconThemeData(color: semantics.ink, size: 22),
        actionsIconTheme: IconThemeData(color: semantics.ink, size: 22),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: semantics.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.all(Radii.lg),
          side: BorderSide(color: semantics.hairline),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(Touch.minTarget, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.xl,
            vertical: Space.base,
          ),
          shape: RoundedRectangleBorder(borderRadius: Radii.all(Radii.md)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(Touch.minTarget, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.xl,
            vertical: Space.base,
          ),
          side: BorderSide(color: semantics.hairline),
          foregroundColor: semantics.ink,
          shape: RoundedRectangleBorder(borderRadius: Radii.all(Radii.md)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(Touch.minTarget, Touch.minTarget),
          foregroundColor: semantics.accent,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: Radii.all(Radii.sm)),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Touch.minSize,
          foregroundColor: semantics.ink,
          shape: RoundedRectangleBorder(borderRadius: Radii.all(Radii.md)),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
          side: WidgetStatePropertyAll(BorderSide(color: semantics.hairline)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Radii.all(Radii.md)),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: semantics.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: semantics.inkFaint),
        prefixIconColor: semantics.inkFaint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.base,
          vertical: Space.md,
        ),
        border: OutlineInputBorder(
          borderRadius: Radii.all(Radii.md),
          borderSide: BorderSide(color: semantics.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.all(Radii.md),
          borderSide: BorderSide(color: semantics.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.all(Radii.md),
          borderSide: BorderSide(color: semantics.accent, width: 2),
        ),
      ),

      chipTheme: ChipThemeData(
        side: BorderSide(color: semantics.hairline),
        backgroundColor: semantics.surface,
        selectedColor: semantics.accentTint,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        shape: RoundedRectangleBorder(borderRadius: Radii.all(Radii.sm)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: semantics.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: Radii.all(Radii.xl)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: semantics.inkMuted,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: semantics.surface,
        modalBackgroundColor: semantics.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: semantics.hairline,
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheet),
        clipBehavior: Clip.antiAlias,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: semantics.accent,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: Radii.all(Radii.lg)),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.inkOn : AppColors.ink,
        actionTextColor: isDark ? AppColors.cobalt : AppColors.cobaltLight,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.ink : AppColors.paperRaised,
        ),
        shape: RoundedRectangleBorder(borderRadius: Radii.all(Radii.md)),
        insetPadding: const EdgeInsets.all(Space.base),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: semantics.inkFaint,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: semantics.inkMuted,
        ),
        minVerticalPadding: Space.md,
        shape: RoundedRectangleBorder(borderRadius: Radii.all(Radii.md)),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: semantics.accent,
        inactiveTrackColor: semantics.hairline,
        thumbColor: semantics.accent,
        trackHeight: 4,
        overlayColor: semantics.accent.withValues(alpha: 0.12),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : semantics.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? semantics.accent
              : semantics.surfaceSunken,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: semantics.accent,
        linearTrackColor: semantics.hairline,
        linearMinHeight: 3,
      ),

      dividerTheme: DividerThemeData(
        color: semantics.hairline,
        thickness: 1,
        space: 1,
      ),

      textSelectionTheme: TextSelectionThemeData(
        selectionColor: semantics.accent.withValues(alpha: 0.24),
        cursorColor: semantics.accent,
        selectionHandleColor: semantics.accent,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.inkOn : AppColors.ink,
          borderRadius: Radii.all(Radii.sm),
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: isDark ? AppColors.ink : AppColors.paperRaised,
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
