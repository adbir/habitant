import 'package:web/web.dart' as web;

import 'token_storage.dart';

/// Creates the web [TokenStorage] implementation.
TokenStorage createTokenStorage() => _WebTokenStorage();

class _WebTokenStorage implements TokenStorage {
  static const _key = 'auth_token';

  @override
  Future<String?> read() async =>
      web.window.sessionStorage.getItem(_key);

  @override
  Future<void> write(String token) async =>
      web.window.sessionStorage.setItem(_key, token);

  @override
  Future<void> delete() async =>
      web.window.sessionStorage.removeItem(_key);
}
