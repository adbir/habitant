import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';

/// Reasons a login attempt can fail — mapped to localized strings in the UI.
enum LoginError {
  emptyFields,
  invalidCredentials,
  emailNotConfirmed,
  rateLimited,
  generic,
}

/// Manages login form state.
///
/// Navigation after a successful login is handled automatically by
/// [AppRouter]'s redirect, which listens to [AuthService].
class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  LoginError? _error;

  LoginViewModel({required AuthService authService})
      : _authService = authService;

  bool get isLoading => _isLoading;
  LoginError? get error => _error;

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _error = LoginError.emptyFields;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed')) {
        _error = LoginError.emailNotConfirmed;
      } else if (e.statusCode == '429' || msg.contains('rate limit') || msg.contains('too many')) {
        _error = LoginError.rateLimited;
      } else if (e.statusCode == '400' || msg.contains('invalid')) {
        _error = LoginError.invalidCredentials;
      } else {
        _error = LoginError.generic;
      }
    } catch (e, s) {
      developer.log(
        'Login failed',
        name: 'LoginViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _error = LoginError.generic;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
