/// Integration test: full login flow using FakeApiClient seed data.
///
/// Covers:
///  - Unauthenticated start → /login
///  - Wrong password → error message, stays on /login
///  - Tenant login (lars@example.com) → /tenant, two nav tabs
///  - Tenant taps Profile tab → /tenant/profile, sees name + address
///  - Staff login (tech@aab.dk) → /staff, single Issues tab
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:beboer_app/app_router.dart';
import 'package:beboer_app/core/services/theme_mode_service.dart';
import 'package:beboer_app/core/widgets/app_shell.dart';
import 'package:beboer_app/dev/fake_api_client.dart';
import 'package:beboer_app/dev/fake_auth_service.dart';
import 'package:beboer_app/features/auth/presentation/login_screen.dart';
import 'package:beboer_app/features/maintenance/presentation/maintenance_dashboard_screen.dart';
import 'package:beboer_app/features/tenant/presentation/tenant_home_screen.dart';
import 'package:beboer_app/features/tenant/presentation/tenant_profile_screen.dart';
import 'package:beboer_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// App factory
// ---------------------------------------------------------------------------

/// Builds a self-contained test app that mirrors the real AppRouter shell
/// structure but wires [FakeApiClient] + [FakeAuthService] instead of
/// Supabase. No network calls, no Supabase.initialize() required.
Widget _buildApp() {
  final fakeApi = FakeApiClient();
  final fakeAuth = FakeAuthService(fakeApi);
  final themeMode = ThemeModeService();

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: fakeAuth,
    redirect: (context, state) => computeAuthRedirect(
      isAuthenticated: fakeAuth.isAuthenticated,
      role: fakeAuth.role,
      location: state.uri.path,
      joinInProgress: fakeAuth.joinInProgress,
    ),
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => LoginScreen(authService: fakeAuth),
      ),

      // ── Tenant shell ───────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          final l10n = AppLocalizations.of(context)!;
          final path = state.uri.path;
          return AppShell(
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: l10n.myIssues,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: l10n.profileTitle,
              ),
            ],
            selectedIndex: path.startsWith('/tenant/profile') ? 1 : 0,
            onDestinationSelected: (i) =>
                context.go(i == 0 ? '/tenant' : '/tenant/profile'),
            authService: fakeAuth,
            themeModeService: themeMode,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/tenant',
            builder: (_, _) =>
                TenantHomeScreen(apiClient: fakeApi, authService: fakeAuth),
          ),
          GoRoute(
            path: '/tenant/profile',
            builder: (_, _) =>
                TenantProfileScreen(apiClient: fakeApi, authService: fakeAuth),
          ),
        ],
      ),

      // ── Staff shell ────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          final l10n = AppLocalizations.of(context)!;
          return AppShell(
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.assignment_outlined),
                selectedIcon: const Icon(Icons.assignment),
                label: l10n.maintenanceTitle,
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) => context.go('/staff'),
            authService: fakeAuth,
            themeModeService: themeMode,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/staff',
            builder: (_, _) => MaintenanceDashboardScreen(
              apiClient: fakeApi,
              authService: fakeAuth,
            ),
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // Force English so test assertions use known strings regardless of
    // the device/browser locale.
    locale: const Locale('en'),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Types [email] and [password] into the login form and taps Log in.
Future<void> _login(
  WidgetTester tester,
  String email,
  String password,
) async {
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.tap(find.text('Log in'));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('unauthenticated start: shows login screen', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('wrong password: error shown, stays on login screen',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await _login(tester, 'lars@example.com', 'wrong-password');

    expect(find.text('Incorrect email or password.'), findsOneWidget);
    // Still on the login screen — no nav shell visible.
    final shellVisible =
        find.byKey(AppShell.navBarKey).evaluate().isNotEmpty ||
            find.byKey(AppShell.navRailKey).evaluate().isNotEmpty;
    expect(shellVisible, isFalse, reason: 'should not have navigated');
  });

  testWidgets('tenant login: lars reaches tenant home with two nav tabs',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await _login(tester, 'lars@example.com', 'password');

    // Navigation shell is visible. AppShell renders a NavigationBar on narrow
    // viewports and a NavigationRail on wide ones — check for either.
    final shellVisible =
        find.byKey(AppShell.navBarKey).evaluate().isNotEmpty ||
            find.byKey(AppShell.navRailKey).evaluate().isNotEmpty;
    expect(shellVisible, isTrue, reason: 'navigation shell not found');

    // Both tenant destinations are present.
    expect(find.text('My issues'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Lars's seed issue is in the list.
    expect(find.textContaining('Radiator'), findsOneWidget);
  });

  testWidgets('tenant profile tab: shows name and current address',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await _login(tester, 'lars@example.com', 'password');

    // Tap the Profile tab.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Profile screen loaded with Lars's data.
    expect(find.text('Lars Hansen'), findsOneWidget);
    // His address should be visible.
    expect(find.textContaining('Rentemestervej'), findsOneWidget);
  });

  testWidgets('staff login: tech reaches staff home with Issues tab',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await _login(tester, 'tech@aab.dk', 'password');

    // Staff shell has a single Issues tab.
    expect(find.text('Issues'), findsOneWidget);

    // Tenant tabs must not be visible.
    expect(find.text('My issues'), findsNothing);
    expect(find.text('Profile'), findsNothing);
  });
}
