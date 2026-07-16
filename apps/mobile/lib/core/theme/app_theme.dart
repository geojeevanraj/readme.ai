import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Global visual language for ReadMe.ai.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    final scheme = base.copyWith(
      primary: isDark ? const Color(0xFFADB5FF) : AppColors.cobalt,
      onPrimary: isDark ? AppColors.ink : Colors.white,
      primaryContainer: isDark ? const Color(0xFF30345B) : AppColors.lavender,
      onPrimaryContainer: isDark ? const Color(0xFFE6E7FF) : AppColors.ink,
      secondary: isDark ? const Color(0xFFFFCC96) : const Color(0xFF9C5B13),
      secondaryContainer: isDark
          ? const Color(0xFF49331F)
          : const Color(0xFFFFE5C5),
      surface: isDark ? AppColors.darkSurface : AppColors.paperRaised,
      onSurface: isDark ? const Color(0xFFF2F0EA) : AppColors.ink,
      onSurfaceVariant: isDark ? const Color(0xFFB9B8C2) : AppColors.inkSoft,
      outline: isDark ? const Color(0xFF777781) : const Color(0xFFB9B7B0),
      outlineVariant: isDark
          ? const Color(0xFF363741)
          : const Color(0xFFE4E0D8),
    );

    final baseTheme = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = baseTheme.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkCanvas : AppColors.paper,
      canvasColor: isDark ? AppColors.darkCanvas : AppColors.paper,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -2.4,
          height: 0.98,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.6,
          height: 1.02,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? AppColors.darkRaised : AppColors.paperRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkRaised : AppColors.paperRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkRaised : AppColors.paperRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.paperRaised,
        modalBackgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.paperRaised,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFFF0EEE8) : AppColors.ink,
        contentTextStyle: TextStyle(
          color: isDark ? AppColors.ink : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
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
