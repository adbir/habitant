import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/models/issue.dart';
import 'core/models/user_role.dart';
import 'core/services/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/services/theme_mode_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/maintenance/presentation/issue_detail_screen.dart';
import 'features/maintenance/presentation/maintenance_dashboard_screen.dart';
import 'features/tenant/presentation/report_issue_screen.dart';
import 'features/tenant/presentation/tenant_home_screen.dart';
import 'features/tenant/presentation/tenant_issue_detail_screen.dart';

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
          builder: (context, state) =>
              LoginScreen(authService: _authService),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => SignupScreen(
            apiClient: _apiClient,
            authService: _authService,
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
          ],
        ),
      ],
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final isAuth = _authService.isAuthenticated;
    final location = state.matchedLocation;
    final publicRoutes = {'/login', '/signup'};

    if (!isAuth) {
      return publicRoutes.contains(location) ? null : '/login';
    }

    // Authenticated — redirect away from auth screens.
    if (publicRoutes.contains(location)) {
      return _authService.role?.isStaff == true ? '/staff' : '/tenant';
    }

    return null;
  }
}
