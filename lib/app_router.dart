import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/models/housing.dart';
import 'core/models/issue.dart';
import 'core/models/user_role.dart';
import 'core/services/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/services/theme_mode_service.dart';
import 'core/widgets/app_shell.dart';
import 'features/auth/presentation/admin_invite_screen.dart';
import 'features/auth/presentation/join_screen.dart';
import 'features/staff/presentation/admin_dashboard_screen.dart';
import 'features/staff/presentation/housing_detail_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/maintenance/presentation/issue_detail_screen.dart';
import 'features/maintenance/presentation/maintenance_dashboard_screen.dart';
import 'features/tenant/presentation/report_issue_screen.dart';
import 'features/tenant/presentation/tenant_home_screen.dart';
import 'features/tenant/presentation/tenant_issue_detail_screen.dart';
import 'l10n/app_localizations.dart';

/// Whether [role] can access the admin dashboard (`/admin` routes).
bool _canAccessAdmin(UserRole role) =>
    role.isAdmin || role.isHousingManager || role.isRootAdmin;

/// Pure redirect logic — no Flutter or Supabase dependencies.
///
/// Extracted so it can be unit-tested without a GoRouter or AuthService
/// instance. [AppRouter._redirect] is a thin wrapper around this function.
String? computeAuthRedirect({
  required bool isAuthenticated,
  required UserRole? role,
  required String location,
  required bool joinInProgress,
  String? pendingRedirect,
}) {
  const publicRoutes = {'/login', '/signup', '/join'};

  if (!isAuthenticated) {
    return publicRoutes.contains(location) ? null : '/login';
  }

  // Authenticated but no profile row yet (incomplete signup/join).
  if (role == null) {
    if (location == '/login' || location == '/signup' || location == '/join') {
      return null;
    }
    if (joinInProgress) return '/join';
    return '/signup';
  }

  // /join is open to all authenticated users — they may be claiming an
  // invitation. Navigation away from /join after a successful claim is handled
  // by JoinScreen itself (via JoinStep.complete), not the router.
  if (location == '/join') return null;

  // Non-admin staff (e.g. maintenanceStaff) may not access /admin routes.
  if (location.startsWith('/admin') && !_canAccessAdmin(role)) {
    return role.isStaff ? '/staff' : '/tenant';
  }

  // Authenticated with a profile — redirect away from other auth screens.
  if (location == '/login' || location == '/signup') {
    if (pendingRedirect != null && pendingRedirect.isNotEmpty) {
      return pendingRedirect;
    }
    if (_canAccessAdmin(role)) return '/admin';
    if (role.isStaff) return '/staff';
    return '/tenant';
  }

  // Non-staff may not access /staff routes.
  if (location.startsWith('/staff') && !role.isStaff) {
    return '/tenant';
  }

  return null;
}

/// Configures all application routes and authentication-based redirects.
///
/// Listens to [AuthService] and re-evaluates redirects on every auth change,
/// so the router automatically sends the user to the right screen after
/// login, signup, or logout.
///
/// Shell routes wrap each role's hub destinations so navigation chrome
/// (rail on desktop, bar on mobile) persists without rebuilding. Detail and
/// action routes sit outside the shells so they render full-screen.
class AppRouter {
  final AuthService _authService;
  final ApiClient _apiClient;
  final ThemeModeService _themeModeService;

  late final GoRouter router;

  AppRouter({
    required AuthService authService,
    required ApiClient apiClient,
    required ThemeModeService themeModeService,
  })  : _authService = authService,
        _apiClient = apiClient,
        _themeModeService = themeModeService {
    router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authService,
      redirect: _redirect,
      routes: [
        // ── Public routes ──────────────────────────────────────────────────
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(
            authService: _authService,
            redirectPath: state.uri.queryParameters['redirect'],
          ),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => SignupScreen(
            authService: _authService,
            verifyEmail: state.extra as String?,
          ),
        ),
        GoRoute(
          path: '/join',
          builder: (context, state) => JoinScreen(
            token: state.uri.queryParameters['token'] ?? '',
            apiClient: _apiClient,
            authService: _authService,
          ),
        ),

        // ── Tenant shell ───────────────────────────────────────────────────
        ShellRoute(
          builder: (context, state, child) {
            final l10n = AppLocalizations.of(context)!;
            return AppShell(
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: l10n.myIssues,
                ),
              ],
              selectedIndex: 0,
              onDestinationSelected: (_) => context.go('/tenant'),
              authService: _authService,
              themeModeService: _themeModeService,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/tenant',
              builder: (context, state) => TenantHomeScreen(
                apiClient: _apiClient,
                authService: _authService,
              ),
            ),
          ],
        ),

        // Tenant detail/action routes — no shell
        GoRoute(
          path: '/tenant/report-issue',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return ReportIssueScreen(
              apiClient: _apiClient,
              authService: _authService,
              addressId: extra['addressId'] as String,
            );
          },
        ),
        GoRoute(
          path: '/tenant/issues/:id',
          builder: (context, state) {
            final issue = state.extra as Issue;
            return TenantIssueDetailScreen(
              apiClient: _apiClient,
              issue: issue,
            );
          },
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
              authService: _authService,
              themeModeService: _themeModeService,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/staff',
              builder: (context, state) => MaintenanceDashboardScreen(
                apiClient: _apiClient,
                authService: _authService,
              ),
            ),
          ],
        ),

        // Staff detail/action routes — no shell
        GoRoute(
          path: '/staff/issues/:id',
          builder: (context, state) {
            final issue = state.extra as Issue;
            return IssueDetailScreen(
              apiClient: _apiClient,
              authService: _authService,
              initialIssue: issue,
            );
          },
        ),
        GoRoute(
          path: '/staff/invite',
          builder: (context, state) => AdminInviteScreen(
            apiClient: _apiClient,
            authService: _authService,
          ),
        ),

        // ── Admin shell ────────────────────────────────────────────────────
        ShellRoute(
          builder: (context, state, child) {
            final l10n = AppLocalizations.of(context)!;
            return AppShell(
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.apartment_outlined),
                  selectedIcon: const Icon(Icons.apartment),
                  label: l10n.adminDashboardTitle,
                ),
              ],
              selectedIndex: 0,
              onDestinationSelected: (_) => context.go('/admin'),
              authService: _authService,
              themeModeService: _themeModeService,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/admin',
              builder: (context, state) => AdminDashboardScreen(
                apiClient: _apiClient,
                authService: _authService,
              ),
            ),
          ],
        ),

        // Admin detail routes — no shell
        GoRoute(
          path: '/admin/housing/:id',
          builder: (context, state) => HousingDetailScreen(
            initialHousing: state.extra as Housing,
            apiClient: _apiClient,
            authService: _authService,
          ),
        ),
      ],
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) =>
      computeAuthRedirect(
        isAuthenticated: _authService.isAuthenticated,
        role: _authService.role,
        location: state.matchedLocation,
        joinInProgress: _authService.joinInProgress,
        pendingRedirect: state.uri.queryParameters['redirect'],
      );
}
