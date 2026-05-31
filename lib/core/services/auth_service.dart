import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_role.dart';

/// Manages authentication state using Supabase Auth.
///
/// Listens to the Supabase auth state stream and resolves the user's
/// application role by checking [staff_user] or [tenant] tables.
/// Notifies listeners on every auth change so [GoRouter] can redirect.
class AuthService extends ChangeNotifier {
  UserRole? _role;
  bool _joinInProgress = false;
  StreamSubscription<AuthState>? _authSubscription;

  static SupabaseClient get _client => Supabase.instance.client;

  AuthService() {
    _authSubscription = _client.auth.onAuthStateChange.listen(
      _onAuthStateChange,
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'Auth state stream error',
          name: 'AuthService',
          level: 1000,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  /// Whether the user currently has an active Supabase session.
  bool get isAuthenticated => _client.auth.currentSession != null;

  /// The user's application role, or null if mid-signup (no profile row yet).
  UserRole? get role => _role;

  /// The authenticated user's UUID — equals tenant_id / staff_user_id in DB.
  String? get tenantId => _client.auth.currentUser?.id;

  /// True while the join wizard is in progress between OTP verification and
  /// tenant row insertion. Prevents [GoRouter] from redirecting to /signup
  /// when [AuthChangeEvent.signedIn] fires before the profile row exists.
  bool get joinInProgress => _joinInProgress;

  /// Called when the join flow starts to prevent the router redirecting
  /// away from /join while the flow is in progress.
  void beginJoin() {
    _joinInProgress = true;
    notifyListeners();
  }

  /// Releases the join gate without completing (invalid token, user left).
  void cancelJoin() {
    if (_joinInProgress) {
      _joinInProgress = false;
      notifyListeners();
    }
  }

  /// Called after the tenant row is inserted in the join flow.
  ///
  /// Re-resolves the role so [GoRouter] redirects to the tenant home screen.
  Future<void> joinComplete() async {
    _joinInProgress = false;
    await _resolveRole();
    notifyListeners();
  }

  /// Restores a persisted session on startup and resolves the role.
  ///
  /// Supabase handles session persistence internally; this only queries
  /// the role from the database when a session already exists.
  Future<void> initialize() async {
    if (isAuthenticated) {
      await _resolveRole();
      notifyListeners();
    }
  }

  /// Signs in with [email] and [password].
  ///
  /// Throws [AuthException] on failure. Navigation is handled automatically
  /// by [GoRouter]'s redirect, which listens to this notifier.
  Future<void> login(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Signals that the signup wizard is complete.
  ///
  /// Re-resolves the role now that the tenant profile row exists, which
  /// causes [GoRouter] to redirect to the tenant home screen.
  Future<void> signupComplete() async {
    await _resolveRole();
    notifyListeners();
  }

  /// Signs out and clears the role.
  Future<void> logout() async {
    _role = null;
    await _client.auth.signOut();
  }

  Future<void> _onAuthStateChange(AuthState state) async {
    switch (state.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        await _resolveRole();
      case AuthChangeEvent.signedOut:
        _role = null;
      default:
        break;
    }
    notifyListeners();
  }

  /// Checks [staff_user] then [tenant] to determine the role.
  ///
  /// If neither row exists but the user's email is confirmed, a bare tenant
  /// row is created automatically so confirmed users are always routed to
  /// the tenant home screen (which shows the awaiting-invitation state).
  Future<void> _resolveRole() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _role = null;
      return;
    }
    try {
      final staffRow = await _client
          .from('staff_user')
          .select('role')
          .eq('staff_user_id', user.id)
          .maybeSingle();

      if (staffRow != null) {
        _role = _parseStaffRole(staffRow['role'] as String);
        return;
      }

      final tenantRow = await _client
          .from('tenant')
          .select('tenant_id')
          .eq('tenant_id', user.id)
          .maybeSingle();

      if (tenantRow != null) {
        _role = UserRole.tenant;
        return;
      }

      // No profile row yet. If email is confirmed, auto-create a bare tenant
      // row so the user lands on the tenant home screen (awaiting invitation).
      if (user.emailConfirmedAt != null && user.email != null) {
        await _client.from('tenant').insert({
          'tenant_id': user.id,
          'email': user.email!,
          'tenant_flags': 0,
        });
        _role = UserRole.tenant;
      } else {
        _role = null;
      }
    } catch (e, s) {
      developer.log(
        'Failed to resolve role',
        name: 'AuthService',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _role = null;
    }
  }

  UserRole _parseStaffRole(String value) => switch (value) {
        'root_admin' => UserRole.rootAdmin,
        'admin' => UserRole.admin,
        'housing_manager' => UserRole.housingManager,
        'maintenance_staff' => UserRole.maintenanceStaff,
        _ => UserRole.admin,
      };

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
