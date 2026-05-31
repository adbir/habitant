import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/models/issue.dart';
import 'core/models/user_role.dart';
import 'core/services/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/services/theme_mode_service.dart';
import 'features/auth/presentation/admin_invite_screen.dart';
import 'features/auth/presentation/join_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/maintenance/presentation/issue_detail_screen.dart';
import 'features/maintenance/presentation/maintenance_dashboard_screen.dart';
import 'features/tenant/presentation/report_issue_screen.dart';
import 'features/tenant/presentation/tenant_home_screen.dart';
import 'features/tenant/presentation/tenant_issue_detail_screen.dart';

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

  // Authenticated with a profile — redirect away from other auth screens.
  if (location == '/login' || location == '/signup') {
    if (pendingRedirect != null && pendingRedirect.isNotEmpty) {
      return pendingRedirect;
    }
    return role.isStaff ? '/staff' : '/tenant';
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
          path: '/tenant',
          builder: (context, state) => TenantHomeScreen(
            apiClient: _apiClient,
            authService: _authService,
          ),
          routes: [
            GoRoute(
              path: 'report-issue',
              builder: (context, state) {
                final extra =
                    state.extra as Map<String, dynamic>;
                return ReportIssueScreen(
                  apiClient: _apiClient,
                  authService: _authService,
                  addressId: extra['addressId'] as String,
                );
              },
            ),
            GoRoute(
              path: 'issues/:id',
              builder: (context, state) {
                final issue = state.extra as Issue;
                return TenantIssueDetailScreen(
                  apiClient: _apiClient,
                  issue: issue,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/staff',
          builder: (context, state) => MaintenanceDashboardScreen(
            apiClient: _apiClient,
            authService: _authService,
            themeModeService: _themeModeService,
          ),
          routes: [
            GoRoute(
              path: 'issues/:id',
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
              path: 'invite',
              builder: (context, state) => AdminInviteScreen(
                apiClient: _apiClient,
                authService: _authService,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/join',
          builder: (context, state) => JoinScreen(
            token: state.uri.queryParameters['token'] ?? '',
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
