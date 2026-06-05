import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_role.dart';
import 'auth_service.dart';

/// Production [AuthService] backed by Supabase Auth.
///
/// Listens to the Supabase auth-state stream and resolves the user's role by
/// querying the [staff_user] / [tenant] tables. Used in release builds only.
class SupabaseAuthService extends AuthService {
  UserRole? _role;
  bool _joinInProgress = false;
  StreamSubscription<AuthState>? _authSubscription;

  static SupabaseClient get _client => Supabase.instance.client;

  SupabaseAuthService() {
    _authSubscription = _client.auth.onAuthStateChange.listen(
      _onAuthStateChange,
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'Auth state stream error',
          name: 'SupabaseAuthService',
          level: 1000,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  @override
  bool get isAuthenticated => _client.auth.currentSession != null;

  @override
  UserRole? get role => _role;

  @override
  String? get tenantId => _client.auth.currentUser?.id;

  @override
  bool get joinInProgress => _joinInProgress;

  @override
  Future<void> initialize() async {
    if (isAuthenticated) {
      await _resolveRole();
      notifyListeners();
    }
  }

  @override
  Future<void> login(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> logout() async {
    _role = null;
    await _client.auth.signOut();
  }

  @override
  Future<void> signupComplete() async {
    await _resolveRole();
    notifyListeners();
  }

  @override
  Future<void> joinComplete() async {
    _joinInProgress = false;
    await _resolveRole();
    notifyListeners();
  }

  @override
  void beginJoin() {
    _joinInProgress = true;
    notifyListeners();
  }

  @override
  void cancelJoin() {
    if (_joinInProgress) {
      _joinInProgress = false;
      notifyListeners();
    }
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
        name: 'SupabaseAuthService',
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
