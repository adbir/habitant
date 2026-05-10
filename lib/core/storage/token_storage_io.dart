import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_storage.dart';

/// Creates the mobile/desktop [TokenStorage] implementation.
TokenStorage createTokenStorage() => _MobileTokenStorage();

class _MobileTokenStorage implements TokenStorage {
  final _secure = const FlutterSecureStorage();
  static const _key = 'auth_token';

  @override
  Future<String?> read() => _secure.read(key: _key);

  @override
  Future<void> write(String token) => _secure.write(key: _key, value: token);

  @override
  Future<void> delete() => _secure.delete(key: _key);
}
