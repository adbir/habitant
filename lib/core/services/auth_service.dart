import 'package:flutter/foundation.dart';

import '../models/user_role.dart';

/// Abstract authentication service.
///
/// Production: [SupabaseAuthService] — uses Supabase Auth.
/// Development: [FakeAuthService] — fully in-memory, no network.
abstract class AuthService extends ChangeNotifier {
  /// Whether the user currently has an active session.
  bool get isAuthenticated;

  /// The user's application role, or null if mid-signup / not yet resolved.
  UserRole? get role;

  /// The authenticated user's UUID — equals tenant_id / staff_user_id in DB.
  String? get tenantId;

  /// True while the join wizard is in progress between OTP verification and
  /// tenant row insertion. Prevents [GoRouter] from redirecting to /signup
  /// when the auth event fires before the profile row exists.
  bool get joinInProgress;

  /// Restores a persisted session on startup and resolves the role.
  Future<void> initialize();

  /// Signs in with [email] and [password].
  ///
  /// Throws [AuthException] on failure so callers can display the right error.
  Future<void> login(String email, String password);

  /// Signs out and clears the role.
  Future<void> logout();

  /// Signals that the signup wizard is complete.
  Future<void> signupComplete();

  /// Signals that the join wizard is complete and the tenant row now exists.
  Future<void> joinComplete();

  /// Called when the join flow starts to prevent the router redirecting
  /// away from /join while the flow is in progress.
  void beginJoin();

  /// Releases the join gate without completing (invalid token, user left).
  void cancelJoin();
}
