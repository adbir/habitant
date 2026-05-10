import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../models/user_role.dart';
import '../storage/token_storage.dart';
import '../storage/token_storage_io.dart'
    if (dart.library.html) '../storage/token_storage_web.dart';
import 'api_client.dart';

/// Manages authentication state and JWT persistence.
///
/// Notifies listeners on login/logout so GoRouter can redirect accordingly.
/// Inject a shared [ApiClient] instance; [AuthService] keeps its [authToken]
/// in sync automatically.
class AuthService extends ChangeNotifier {
  final ApiClient _apiClient;
  final TokenStorage _storage;

  String? _token;
  UserRole? _role;

  AuthService({required ApiClient apiClient})
      : _apiClient = apiClient,
        _storage = createTokenStorage();

  /// Whether the user currently has an active session.
  bool get isAuthenticated => _token != null;

  /// The current JWT, or null if not logged in.
  String? get token => _token;

  /// The role decoded from the JWT payload, or null if not logged in.
  UserRole? get role => _role;

  /// The tenant/user ID decoded from the JWT `sub` claim.
  String? get tenantId {
    final t = _token;
    if (t == null) return null;
    try {
      final parts = t.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      return payload['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Restores a persisted session from storage.
  ///
  /// Call once during app startup. On web the sessionStorage is already
  /// scoped to the tab lifetime; on mobile this re-hydrates the token
  /// saved by a previous app run.
  Future<void> initialize() async {
    final stored = await _storage.read();
    if (stored != null) {
      _token = stored;
      _role = _roleFromJwt(stored);
      _apiClient.authToken = stored;
      notifyListeners();
    }
  }

  /// Authenticates a user with [email] and [password].
  ///
  /// The returned JWT contains a `role` claim that determines whether the
  /// user is routed to the tenant or staff experience.
  Future<void> login(String email, String password) async {
    try {
      final token = await _apiClient.login(email, password);
      await _applyToken(token);
    } catch (e, s) {
      developer.log(
        'Login failed',
        name: 'AuthService',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Completes signup by persisting [jwt] and notifying the router.
  ///
  /// Call this after the tenant has picked their housing and address. The
  /// router will redirect to the tenant home screen automatically.
  Future<void> signupComplete(String jwt) async => _applyToken(jwt);

  /// Clears the session, removes the stored token, and notifies listeners.
  Future<void> logout() async {
    await _storage.delete();
    _token = null;
    _role = null;
    _apiClient.authToken = null;
    notifyListeners();
  }

  Future<void> _applyToken(String token) async {
    await _storage.write(token);
    _token = token;
    _role = _roleFromJwt(token);
    _apiClient.authToken = token;
    notifyListeners();
  }

  /// Decodes the [UserRole] from the JWT payload's `role` claim.
  ///
  /// Returns null if the token is malformed or the claim is absent.
  UserRole? _roleFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final roleStr = payload['role'] as String?;
      if (roleStr == null) return null;
      return UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.tenant,
      );
    } catch (e, s) {
      developer.log(
        'Failed to decode JWT role',
        name: 'AuthService',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }
}
