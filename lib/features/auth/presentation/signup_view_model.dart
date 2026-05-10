import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
/// After OTP verification Supabase creates the session, but [AuthService]
/// keeps [role] null until [signupComplete] is called at the end of the
/// wizard. This prevents [GoRouter] from redirecting mid-wizard.
class SignupViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthService _authService;

  SignupStep _step = SignupStep.credentials;
  bool _isLoading = false;
  SignupError? _error;

  String _email = '';
  String? _phoneNumber;
  List<Housing> _housings = const [];
  Housing? _selectedHousing;

  static SupabaseClient get _client => Supabase.instance.client;

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

    await _run(
      () async {
        await _client.auth.signUp(email: email, password: password);
        _email = email;
        _phoneNumber =
            phoneNumber != null && phoneNumber.isNotEmpty ? phoneNumber : null;
        _step = SignupStep.verification;
      },
      onEmailTaken: SignupError.emailTaken,
    );
  }

  // ---- Step 2 ---------------------------------------------------------------

  Future<void> submitCode(String code) async {
    await _run(
      () async {
        await _client.auth.verifyOTP(
          email: _email,
          token: code,
          type: OtpType.email,
        );
        _housings = await _apiClient.getHousings();
        _step = SignupStep.housing;
      },
      onInvalidCode: SignupError.invalidCode,
    );
  }

  Future<void> resendCode() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _client.auth.resend(type: OtpType.email, email: _email);
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
    final housing = _selectedHousing;
    if (housing == null) return;

    await _run(() async {
      final userId = _client.auth.currentUser!.id;
      await _client.from('tenant').insert({
        'tenant_id': userId,
        'email': _email,
        if (_phoneNumber != null) 'phone_number': _phoneNumber,
        'current_housing_id': housing.id,
        'current_address_id': address.id,
        'tenant_flags': 1, // bit 0 = is_onboarded
      });
      await _authService.signupComplete();
      // GoRouter redirect takes over from here.
    });
  }

  // ---- Navigation -----------------------------------------------------------

  void goBack() {
    if (_step == SignupStep.address) {
      _step = SignupStep.housing;
      _error = null;
      notifyListeners();
    }
  }

  // ---- Helpers --------------------------------------------------------------

  Future<void> _run(
    Future<void> Function() action, {
    SignupError? onEmailTaken,
    SignupError? onInvalidCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('already been registered')) {
        _error = onEmailTaken ?? SignupError.generic;
      } else if (msg.contains('expired') || msg.contains('invalid')) {
        _error = onInvalidCode ?? SignupError.generic;
      } else {
        _error = SignupError.generic;
      }
    } on PostgrestException catch (e) {
      _error = e.code == '23505'
          ? (onEmailTaken ?? SignupError.generic)
          : SignupError.generic;
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
}
