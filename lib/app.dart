import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

import 'app_router.dart';
import 'core/services/theme_mode_service.dart';

// Tailwind 4.2 Emerald 500 — oklch(69.6% 0.17 162.48)
const _seed = Color(0xFF00A77B);

/// Root widget that wires up the theme and router.
class App extends StatelessWidget {
  final AppRouter appRouter;
  final ThemeModeService themeModeService;

  const App({
    super.key,
    required this.appRouter,
    required this.themeModeService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeModeService,
      builder: (context, _) => MaterialApp.router(
        title: 'Habitant',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Danish first = default when the device locale is not supported.
        locale: const Locale('da'),
        theme: _lightTheme,
        darkTheme: _darkTheme,
        themeMode: themeModeService.mode,
        routerConfig: appRouter.router,
      ),
    );
  }

  // Surfaces and secondary/tertiary roles are overridden to pure grays so
  // that emerald appears only on primary actions (FAB, FilledButton).
  static final _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: _seed,
      onPrimary: Colors.white,
      primaryContainer: _seed,
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFF616161),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFEEEEEE),
      onSecondaryContainer: const Color(0xFF212121),
      tertiary: const Color(0xFF9E9E9E),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFF5F5F5),
      onTertiaryContainer: const Color(0xFF424242),
      surface: Colors.white,
      onSurface: const Color(0xFF1C1C1C),
      onSurfaceVariant: const Color(0xFF616161),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF5F5F5),
      surfaceContainer: const Color(0xFFF0F0F0),
      surfaceContainerHigh: const Color(0xFFEAEAEA),
      surfaceContainerHighest: const Color(0xFFE0E0E0),
      outline: const Color(0xFFBDBDBD),
      outlineVariant: const Color(0xFFE0E0E0),
    ),
  );

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _seed,
      onPrimary: Colors.white,
      primaryContainer: _seed,
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFF9E9E9E),
      onSecondary: const Color(0xFF1C1C1C),
      secondaryContainer: const Color(0xFF2A2A2A),
      onSecondaryContainer: const Color(0xFFE0E0E0),
      tertiary: const Color(0xFF757575),
      onTertiary: const Color(0xFFF5F5F5),
      tertiaryContainer: const Color(0xFF2A2A2A),
      onTertiaryContainer: const Color(0xFFBDBDBD),
      surface: const Color(0xFF121212),
      onSurface: const Color(0xFFF5F5F5),
      onSurfaceVariant: const Color(0xFFB0B0B0),
      surfaceContainerLowest: const Color(0xFF0A0A0A),
      surfaceContainerLow: const Color(0xFF1A1A1A),
      surfaceContainer: const Color(0xFF1E1E1E),
      surfaceContainerHigh: const Color(0xFF242424),
      surfaceContainerHighest: const Color(0xFF2A2A2A),
      outline: const Color(0xFF424242),
      outlineVariant: const Color(0xFF2A2A2A),
    ),
  );
}
