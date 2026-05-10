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
  /// Returns null if neither row exists — the mid-signup state where the
  /// user has verified their email but has not yet created their profile.
  Future<void> _resolveRole() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _role = null;
      return;
    }
    try {
      final staffRow = await _client
          .from('staff_user')
          .select('role')
          .eq('staff_user_id', userId)
          .maybeSingle();

      if (staffRow != null) {
        _role = _parseStaffRole(staffRow['role'] as String);
        return;
      }

      final tenantRow = await _client
          .from('tenant')
          .select('tenant_id')
          .eq('tenant_id', userId)
          .maybeSingle();

      _role = tenantRow != null ? UserRole.tenant : null;
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
