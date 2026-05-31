import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beboer_app/app_router.dart';
import 'package:beboer_app/core/models/user_role.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String? redirect({
    required bool isAuthenticated,
    required UserRole? role,
    required String location,
    bool joinInProgress = false,
    String? pendingRedirect,
  }) =>
      computeAuthRedirect(
        isAuthenticated: isAuthenticated,
        role: role,
        location: location,
        joinInProgress: joinInProgress,
        pendingRedirect: pendingRedirect,
      );

  // ---------------------------------------------------------------------------
  // Unauthenticated user
  // ---------------------------------------------------------------------------

  group('unauthenticated user', () {
    test('is allowed on /login', () {
      check(redirect(isAuthenticated: false, role: null, location: '/login'))
          .isNull();
    });

    test('is allowed on /signup', () {
      check(redirect(isAuthenticated: false, role: null, location: '/signup'))
          .isNull();
    });

    test('is allowed on /join', () {
      check(redirect(isAuthenticated: false, role: null, location: '/join'))
          .isNull();
    });

    test('is sent to /login from /tenant', () {
      check(redirect(isAuthenticated: false, role: null, location: '/tenant'))
          .equals('/login');
    });

    test('is sent to /login from /staff', () {
      check(redirect(isAuthenticated: false, role: null, location: '/staff'))
          .equals('/login');
    });

    test('is sent to /login from any unknown route', () {
      check(
        redirect(isAuthenticated: false, role: null, location: '/anything'),
      ).equals('/login');
    });
  });

  // ---------------------------------------------------------------------------
  // Authenticated, no role (mid-signup or mid-join for new user)
  // ---------------------------------------------------------------------------

  group('authenticated, role null', () {
    test('is allowed on /login', () {
      check(redirect(isAuthenticated: true, role: null, location: '/login'))
          .isNull();
    });

    test('is allowed on /signup', () {
      check(redirect(isAuthenticated: true, role: null, location: '/signup'))
          .isNull();
    });

    test('is allowed on /join', () {
      check(redirect(isAuthenticated: true, role: null, location: '/join'))
          .isNull();
    });

    test('is sent to /signup from /tenant', () {
      check(redirect(isAuthenticated: true, role: null, location: '/tenant'))
          .equals('/signup');
    });

    test('is sent to /join from /tenant when joinInProgress', () {
      check(
        redirect(
          isAuthenticated: true,
          role: null,
          location: '/tenant',
          joinInProgress: true,
        ),
      ).equals('/join');
    });

    test('is sent to /signup from any unknown route', () {
      check(
        redirect(isAuthenticated: true, role: null, location: '/anything'),
      ).equals('/signup');
    });
  });

  // ---------------------------------------------------------------------------
  // pendingRedirect — used after login when a redirect param is in the URL
  // ---------------------------------------------------------------------------

  group('pendingRedirect', () {
    test('authenticated tenant on /login with pendingRedirect goes there', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.tenant,
          location: '/login',
          pendingRedirect: '/join?token=abc',
        ),
      ).equals('/join?token=abc');
    });

    test('authenticated admin on /login with pendingRedirect goes there', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.admin,
          location: '/login',
          pendingRedirect: '/join?token=abc',
        ),
      ).equals('/join?token=abc');
    });

    test('pendingRedirect is ignored when null', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.tenant,
          location: '/login',
        ),
      ).equals('/tenant');
    });

    test('pendingRedirect is ignored when empty string', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.tenant,
          location: '/login',
          pendingRedirect: '',
        ),
      ).equals('/tenant');
    });

    test('authenticated tenant on /signup with pendingRedirect goes there', () {
      // User created an account via /signup?redirect=/join?token=X
      // After signup completes the router should honour the redirect.
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.tenant,
          location: '/signup',
          pendingRedirect: '/join?token=abc',
        ),
      ).equals('/join?token=abc');
    });

    test('pendingRedirect is ignored for unauthenticated users', () {
      // Unauthenticated users are allowed to stay on /login — no redirect.
      check(
        redirect(
          isAuthenticated: false,
          role: null,
          location: '/login',
          pendingRedirect: '/join?token=abc',
        ),
      ).isNull();
    });
  });

  // ---------------------------------------------------------------------------
  // Authenticated tenant
  // ---------------------------------------------------------------------------

  group('authenticated tenant', () {
    test('is redirected from /login to /tenant', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.tenant,
          location: '/login',
        ),
      ).equals('/tenant');
    });

    test('is redirected from /signup to /tenant', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.tenant,
          location: '/signup',
        ),
      ).equals('/tenant');
    });

    test('authenticated tenant on /join is allowed (invitation claim)', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.tenant,
          location: '/join',
          joinInProgress: false,
        ),
      ).isNull();
    });

    test('authenticated tenant on /join is allowed regardless of joinInProgress',
        () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.tenant,
          location: '/join',
          joinInProgress: true,
        ),
      ).isNull();
    });

    test('is allowed on /tenant', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.tenant,
          location: '/tenant',
        ),
      ).isNull();
    });

    test('is redirected from /staff to /tenant', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.tenant,
          location: '/staff',
        ),
      ).equals('/tenant');
    });

    test('is redirected from /staff/issues/123 to /tenant', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.tenant,
          location: '/staff/issues/123',
        ),
      ).equals('/tenant');
    });
  });

  // ---------------------------------------------------------------------------
  // Authenticated staff (admin)
  // ---------------------------------------------------------------------------

  group('authenticated admin', () {
    test('is redirected from /login to /staff', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.admin,
          location: '/login',
        ),
      ).equals('/staff');
    });

    test('is redirected from /signup to /staff', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.admin,
          location: '/signup',
        ),
      ).equals('/staff');
    });

    test('authenticated admin on /join is allowed (invitation claim)', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.admin,
          location: '/join',
          joinInProgress: false,
        ),
      ).isNull();
    });

    test('is allowed on /staff', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.admin,
          location: '/staff',
        ),
      ).isNull();
    });

    test('is allowed on /staff/issues/123', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.admin,
          location: '/staff/issues/123',
        ),
      ).isNull();
    });
  });

  // ---------------------------------------------------------------------------
  // Authenticated maintenance staff
  // ---------------------------------------------------------------------------

  group('authenticated maintenanceStaff', () {
    test('is redirected from /login to /staff', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.maintenanceStaff,
          location: '/login',
        ),
      ).equals('/staff');
    });

    test('is allowed on /staff', () {
      check(
        redirect(
          isAuthenticated: true,
          role: UserRole.maintenanceStaff,
          location: '/staff',
        ),
      ).isNull();
    });
  });
}
