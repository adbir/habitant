import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/models/address.dart';
import '../../../core/models/housing.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

/// The four sequential steps of the signup wizard.
enum SignupStep { credentials, verification, housing, address }

/// Reasons a signup step can fail — mapped to localized strings in the UI.
enum SignupError {
  emptyFields,
  passwordMismatch,
  passwordTooShort,
  emailTaken,
  invalidCode,
  generic,
}

/// Orchestrates the four-step signup wizard.
///
/// The JWT received after email verification is held internally until the
/// tenant finishes picking housing and address, at which point it is handed
/// to [AuthService]. This prevents GoRouter from firing a redirect
/// mid-wizard.
class SignupViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthService _authService;

  SignupStep _step = SignupStep.credentials;
  bool _isLoading = false;
  SignupError? _error;

  String _email = '';
  String? _pendingJwt;
  List<Housing> _housings = const [];
  Housing? _selectedHousing;

  SignupViewModel({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  SignupStep get step => _step;
  bool get isLoading => _isLoading;
  SignupError? get error => _error;
  String get email => _email;
  List<Housing> get housings => _housings;
  Housing? get selectedHousing => _selectedHousing;

  List<Address> get availableAddresses =>
      _selectedHousing?.addresses.where((a) => !a.isOccupied).toList() ??
      const [];

  // ---- Step 1 ---------------------------------------------------------------

  Future<void> submitCredentials(
    String email,
    String password,
    String confirmPassword, {
    String? phoneNumber,
  }) async {
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _setError(SignupError.emptyFields);
      return;
    }
    if (password != confirmPassword) {
      _setError(SignupError.passwordMismatch);
      return;
    }
    if (password.length < 8) {
      _setError(SignupError.passwordTooShort);
      return;
    }

    await _run(() async {
      await _apiClient.signup(
        email,
        password,
        phoneNumber: phoneNumber?.isEmpty == true ? null : phoneNumber,
      );
      _email = email;
      _step = SignupStep.verification;
    }, on409: SignupError.emailTaken);
  }

  // ---- Step 2 ---------------------------------------------------------------

  Future<void> submitCode(String code) async {
    await _run(() async {
      final jwt = await _apiClient.verifyEmail(_email, code);
      _pendingJwt = jwt;
      _housings = await _apiClient.getHousings();
      _step = SignupStep.housing;
    }, on422: SignupError.invalidCode);
  }

  Future<void> resendCode() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiClient.resendVerificationCode(_email);
    } catch (_) {
      // Best-effort — don't surface resend errors.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---- Step 3 ---------------------------------------------------------------

  void selectHousing(Housing housing) {
    _selectedHousing = housing;
    _step = SignupStep.address;
    _error = null;
    notifyListeners();
  }

  // ---- Step 4 ---------------------------------------------------------------

  Future<void> selectAddress(Address address) async {
    final jwt = _pendingJwt;
    final housing = _selectedHousing;
    if (jwt == null || housing == null) return;

    final tenantId = _subFromJwt(jwt);
    if (tenantId == null) {
      _setError(SignupError.generic);
      return;
    }

    await _run(() async {
      _apiClient.authToken = jwt;
      await _apiClient.setTenantHousingAddress(
        tenantId,
        housing.id,
        address.id,
      );
      await _authService.signupComplete(jwt);
      // GoRouter redirect takes over from here.
    });
  }

  // ---- Navigation -----------------------------------------------------------

  /// Navigates back from the address step to the housing step.
  void goBack() {
    if (_step == SignupStep.address) {
      _step = SignupStep.housing;
      _error = null;
      notifyListeners();
    }
  }

  // ---- Helpers --------------------------------------------------------------

  /// Runs [action] with loading state, catching [ApiException]s.
  Future<void> _run(
    Future<void> Function() action, {
    SignupError? on409,
    SignupError? on422,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (e) {
      _error = switch (e.statusCode) {
        409 => on409 ?? SignupError.generic,
        422 => on422 ?? SignupError.generic,
        _ => SignupError.generic,
      };
    } catch (e, s) {
      developer.log(
        'Signup step failed',
        name: 'SignupViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _error = SignupError.generic;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setError(SignupError error) {
    _error = error;
    notifyListeners();
  }

  String? _subFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      return payload['sub'] as String?;
    } catch (_) {
      return null;
    }
  }
}
