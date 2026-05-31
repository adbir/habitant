import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';

/// The sequential steps of the signup wizard.
enum SignupStep { credentials, verification }

/// Reasons a signup step can fail — mapped to localized strings in the UI.
enum SignupError {
  emptyFields,
  passwordMismatch,
  passwordTooShort,
  emailTaken,
  invalidCode,
  rateLimited,
  generic,
}

/// Orchestrates the two-step signup wizard (credentials → OTP verification).
///
/// After OTP verification a bare tenant row is inserted with no housing or
/// address. Apartment assignment happens separately via the invitation flow
/// (/join?token=...). [AuthService.signupComplete] is called once the row is
/// inserted so [GoRouter] redirects to the tenant home screen.
class SignupViewModel extends ChangeNotifier {
  final AuthService _authService;

  SignupStep _step = SignupStep.credentials;
  bool _isLoading = false;
  SignupError? _error;

  String _email = '';
  String? _phoneNumber;

  late final SupabaseClient _client;

  SignupViewModel({
    required AuthService authService,
    String? verifyEmail,
    SupabaseClient? supabaseClient,
  })  : _authService = authService,
        _client = supabaseClient ?? Supabase.instance.client {
    _resumePendingSignup(verifyEmail);
  }

  /// Jumps straight to the verification step when possible.
  ///
  /// Uses [verifyEmail] if supplied (navigated from login's "email not
  /// confirmed" error). Falls back to the current Supabase session when the
  /// user navigated away mid-signup and the session is still alive.
  void _resumePendingSignup(String? verifyEmail) {
    if (verifyEmail != null && verifyEmail.isNotEmpty) {
      _email = verifyEmail;
      _step = SignupStep.verification;
      return;
    }
    final user = _client.auth.currentUser;
    if (user != null &&
        user.emailConfirmedAt == null &&
        user.email != null) {
      _email = user.email!;
      _step = SignupStep.verification;
    }
  }

  SignupStep get step => _step;
  bool get isLoading => _isLoading;
  SignupError? get error => _error;
  String get email => _email;

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
        final userId = _client.auth.currentUser!.id;
        await _client.from('tenant').insert({
          'tenant_id': userId,
          'email': _email,
          if (_phoneNumber != null) 'phone_number': _phoneNumber,
          // Housing and address are assigned via the invitation flow.
          'tenant_flags': 0,
        });
        await _authService.signupComplete();
        // GoRouter redirect takes over from here.
      },
      onInvalidCode: SignupError.invalidCode,
    );
  }

  Future<void> resendCode() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _client.auth.resend(type: OtpType.email, email: _email);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      _error =
          (e.statusCode == '429' ||
                  msg.contains('rate limit') ||
                  msg.contains('too many'))
              ? SignupError.rateLimited
              : SignupError.generic;
    } catch (_) {
      _error = SignupError.generic;
    } finally {
      _isLoading = false;
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
      if (msg.contains('already registered') ||
          msg.contains('already been registered')) {
        _error = onEmailTaken ?? SignupError.generic;
      } else if (e.statusCode == '429' ||
          msg.contains('rate limit') ||
          msg.contains('too many')) {
        _error = SignupError.rateLimited;
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
