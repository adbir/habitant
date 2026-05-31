import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/invitation.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

/// The sequential steps of the invite-based join flow.
enum JoinStep { loading, invalidToken, preview, credentials, verification }

/// Reasons a join step can fail — mapped to localized strings in the UI.
enum JoinError {
  emptyFields,
  passwordMismatch,
  passwordTooShort,
  emailTaken,
  invalidCode,
  generic,
}

/// Orchestrates the invite-based join flow.
///
/// The flow starts by fetching the invitation by token to show an address
/// preview. The user then creates credentials, verifies their email, and is
/// automatically assigned to the pre-determined address — no housing or
/// address picker is shown.
///
/// The [AuthService.beginJoin] flag is set before [supabase.auth.signUp] to
/// prevent [GoRouter] from redirecting to /signup when the auth event fires
/// before the tenant row is inserted.
class JoinViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthService _authService;

  JoinStep _step = JoinStep.loading;
  bool _isLoading = false;
  JoinError? _error;

  Invitation? _invitation;
  String _email = '';
  String? _phoneNumber;

  static SupabaseClient get _client => Supabase.instance.client;

  JoinViewModel({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  JoinStep get step => _step;
  bool get isLoading => _isLoading;
  JoinError? get error => _error;
  String get email => _email;
  Invitation? get invitation => _invitation;

  // ---- Token loading --------------------------------------------------------

  Future<void> loadInvitation(String token) async {
    if (token.isEmpty) {
      _step = JoinStep.invalidToken;
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      _invitation = await _apiClient.getInvitationByToken(token);
      _step = JoinStep.preview;
    } on InvitationNotFoundException {
      _step = JoinStep.invalidToken;
    } catch (e, s) {
      developer.log(
        'Failed to load invitation',
        name: 'JoinViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _step = JoinStep.invalidToken;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---- Step: preview --------------------------------------------------------

  void proceed() {
    _step = JoinStep.credentials;
    notifyListeners();
  }

  // ---- Step: credentials ----------------------------------------------------

  Future<void> submitCredentials(
    String email,
    String password,
    String confirmPassword, {
    String? phoneNumber,
  }) async {
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _setError(JoinError.emptyFields);
      return;
    }
    if (password != confirmPassword) {
      _setError(JoinError.passwordMismatch);
      return;
    }
    if (password.length < 8) {
      _setError(JoinError.passwordTooShort);
      return;
    }

    // Set the flag before signUp so the auth event does not trigger a redirect
    // to /signup while the tenant row has not yet been inserted.
    _authService.beginJoin();

    await _run(
      () async {
        await _client.auth.signUp(email: email, password: password);
        _email = email;
        _phoneNumber =
            phoneNumber != null && phoneNumber.isNotEmpty ? phoneNumber : null;
        _step = JoinStep.verification;
      },
      onEmailTaken: JoinError.emailTaken,
    );
  }

  // ---- Step: verification ---------------------------------------------------

  Future<void> submitCode(String code) async {
    final inv = _invitation;
    if (inv == null) return;

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
          'current_housing_id': inv.address!.housingId,
          'current_address_id': inv.addressId,
          'tenant_flags': 1, // bit 0 = is_onboarded
        });

        await _authService.joinComplete();
        // GoRouter redirect takes over from here.
      },
      onInvalidCode: JoinError.invalidCode,
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

  // ---- Helpers --------------------------------------------------------------

  Future<void> _run(
    Future<void> Function() action, {
    JoinError? onEmailTaken,
    JoinError? onInvalidCode,
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
        _error = onEmailTaken ?? JoinError.generic;
      } else if (msg.contains('expired') || msg.contains('invalid')) {
        _error = onInvalidCode ?? JoinError.generic;
      } else {
        _error = JoinError.generic;
      }
    } on PostgrestException catch (e) {
      _error = e.code == '23505'
          ? (onEmailTaken ?? JoinError.generic)
          : JoinError.generic;
    } catch (e, s) {
      developer.log(
        'Join step failed',
        name: 'JoinViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _error = JoinError.generic;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setError(JoinError error) {
    _error = error;
    notifyListeners();
  }
}
