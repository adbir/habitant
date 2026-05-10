/// Abstract token storage with platform-specific implementations.
///
/// Use the [createTokenStorage] factory function (defined via conditional
/// imports) to obtain the correct implementation for the current platform:
/// - Web: sessionStorage (cleared when the browser tab closes)
/// - Mobile/Desktop: flutter_secure_storage (persists across app restarts)
abstract class TokenStorage {
  /// Returns the stored auth token, or null if none is saved.
  Future<String?> read();

  /// Persists [token] to the platform-appropriate secure store.
  Future<void> write(String token);

  /// Removes the stored auth token.
  Future<void> delete();
}
