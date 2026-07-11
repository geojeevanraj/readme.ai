import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'l10n/generated/app_localizations.dart';

/// Root application widget.
///
/// Wires routing, theming, theme-mode state, and localization. It is a
/// [ConsumerWidget] so it rebuilds when the router or theme mode changes.
class ReadMeApp extends ConsumerWidget {
  const ReadMeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final devAuth = ref.watch(appConfigProvider).devAuth;

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      // Development-only corner ribbon; never shown in production builds.
      builder: devAuth
          ? (context, child) => Banner(
              message: 'Dev Mode',
              location: BannerLocation.topEnd,
              color: Colors.deepOrange,
              child: child ?? const SizedBox.shrink(),
            )
          : null,
    );
  }
}
