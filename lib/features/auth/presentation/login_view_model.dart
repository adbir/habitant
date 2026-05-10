import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

/// Reasons a login attempt can fail — mapped to localized strings in the UI.
enum LoginError { emptyFields, invalidCredentials, generic }

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
    } on ApiException catch (e) {
      _error = e.statusCode == 401
          ? LoginError.invalidCredentials
          : LoginError.generic;
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
