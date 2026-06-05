import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/user_role.dart';
import '../core/services/api_client.dart';
import '../core/services/auth_service.dart';
import 'fake_api_client.dart';

/// Development [AuthService] — fully in-memory, no Supabase network calls.
///
/// Login is validated against [FakeApiClient]'s seed credentials and a fake
/// JWT is decoded to populate role and tenant ID. No Supabase calls are made
/// during the normal login/logout cycle.
///
/// Note: [JoinViewModel] still uses Supabase OTP directly for the join flow.
/// [joinComplete] falls back to the locally-cached Supabase session for that
/// path only. That is a pre-existing coupling and is a separate task to fix.
class FakeAuthService extends AuthService {
  final FakeApiClient _apiClient;

  UserRole? _role;
  String? _userId;
  bool _joinInProgress = false;

  FakeAuthService(this._apiClient);

  @override
  bool get isAuthenticated => _userId != null;

  @override
  UserRole? get role => _role;

  @override
  String? get tenantId => _userId;

  @override
  bool get joinInProgress => _joinInProgress;

  @override
  Future<void> initialize() async {
    // No session persistence for normal fake logins.
    // If the user previously completed the join flow (Supabase OTP path),
    // restore that session so the app doesn't boot to /login.
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) {
      _userId = supabaseUser.id;
      await _resolveRoleFromApi();
      notifyListeners();
    }
  }

  @override
  Future<void> login(String email, String password) async {
    try {
      final jwt = await _apiClient.login(email, password);
      _applyJwt(jwt);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Rethrow as AuthException so LoginViewModel shows the right message.
        throw AuthException('Invalid login credentials', statusCode: '400');
      }
      rethrow;
    }
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    _userId = null;
    _role = null;
    _joinInProgress = false;
    // Also clear the Supabase session in case the join flow was used.
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    notifyListeners();
  }

  @override
  Future<void> signupComplete() async {
    _userId ??= Supabase.instance.client.auth.currentUser?.id;
    await _resolveRoleFromApi();
    notifyListeners();
  }

  @override
  Future<void> joinComplete() async {
    _joinInProgress = false;
    _userId ??= Supabase.instance.client.auth.currentUser?.id;
    await _resolveRoleFromApi();
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

  /// Decodes the fake JWT and populates [_userId] and [_role].
  void _applyJwt(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    ) as Map<String, dynamic>;
    _userId = payload['sub'] as String?;
    final roleName = payload['role'] as String?;
    _role = roleName == null
        ? null
        : UserRole.values.firstWhere(
            (r) => r.name == roleName,
            orElse: () => UserRole.tenant,
          );
  }

  /// Resolves [_role] from [FakeApiClient] when no JWT is available
  /// (e.g. after the join flow which authenticates via Supabase OTP).
  Future<void> _resolveRoleFromApi() async {
    final id = _userId;
    if (id == null) {
      _role = null;
      return;
    }
    if (_role != null) return; // Already set from JWT — nothing to do.
    try {
      await _apiClient.getTenantProfile(id);
      _role = UserRole.tenant;
    } on ApiException {
      _role = null;
    } catch (_) {
      _role = null;
    }
  }

}
