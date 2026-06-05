import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:beboer_app/core/services/api_client.dart';
import 'package:beboer_app/features/auth/presentation/join_view_model.dart';

import '../../helpers/fake_auth_service.dart';
import '../../helpers/test_fixtures.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

JoinViewModel makeVm({
  required MockApiClient api,
  required MockAuthService auth,
  required MockSupabaseClient supabase,
}) =>
    JoinViewModel(
      apiClient: api,
      authService: auth,
      supabaseClient: supabase,
    );

void main() {
  late MockApiClient api;
  late MockAuthService auth;
  late MockSupabaseClient supabase;
  late MockGoTrueClient goTrue;

  setUp(() {
    api = MockApiClient();
    auth = MockAuthService();
    supabase = MockSupabaseClient();
    goTrue = MockGoTrueClient();
    when(() => supabase.auth).thenReturn(goTrue);
    stubAuthServiceDefaults(auth);
  });

  // -------------------------------------------------------------------------
  // loadInvitation
  // -------------------------------------------------------------------------

  group('loadInvitation', () {
    test('valid token: step becomes preview and beginJoin is called', () async {
      when(() => api.getInvitationByToken('test-token-uuid'))
          .thenAnswer((_) async => testInvitation);

      final vm = makeVm(api: api, auth: auth, supabase: supabase);
      await vm.loadInvitation('test-token-uuid');

      check(vm.step).equals(JoinStep.preview);
      check(vm.invitation).equals(testInvitation);
      verify(() => auth.beginJoin()).called(1);
      verifyNever(() => auth.cancelJoin());
    });

    test('empty token: step becomes invalidToken without calling the API',
        () async {
      final vm = makeVm(api: api, auth: auth, supabase: supabase);
      await vm.loadInvitation('');

      check(vm.step).equals(JoinStep.invalidToken);
      verifyNever(() => api.getInvitationByToken(any()));
      // Empty token returns early before beginJoin.
      verifyNever(() => auth.beginJoin());
      verifyNever(() => auth.cancelJoin());
    });

    test('invalid token: step becomes invalidToken and cancelJoin is called',
        () async {
      when(() => api.getInvitationByToken('bad-token'))
          .thenThrow(const InvitationNotFoundException());

      final vm = makeVm(api: api, auth: auth, supabase: supabase);
      await vm.loadInvitation('bad-token');

      check(vm.step).equals(JoinStep.invalidToken);
      verify(() => auth.beginJoin()).called(1);
      verify(() => auth.cancelJoin()).called(1);
    });

    test('network error: step becomes invalidToken and cancelJoin is called',
        () async {
      when(() => api.getInvitationByToken(any()))
          .thenThrow(Exception('network error'));

      final vm = makeVm(api: api, auth: auth, supabase: supabase);
      await vm.loadInvitation('some-token');

      check(vm.step).equals(JoinStep.invalidToken);
      verify(() => auth.beginJoin()).called(1);
      verify(() => auth.cancelJoin()).called(1);
    });

    test('is not loading after completion', () async {
      when(() => api.getInvitationByToken(any()))
          .thenAnswer((_) async => testInvitation);

      final vm = makeVm(api: api, auth: auth, supabase: supabase);
      await vm.loadInvitation('any');

      check(vm.isLoading).isFalse();
    });
  });

  // -------------------------------------------------------------------------
  // isAlreadyAuthenticated
  // -------------------------------------------------------------------------

  group('isAlreadyAuthenticated', () {
    test('false when no current user', () {
      when(() => goTrue.currentUser).thenReturn(null);
      final vm = makeVm(api: api, auth: auth, supabase: supabase);
      check(vm.isAlreadyAuthenticated).isFalse();
    });

    test('false when user has no confirmed email', () {
      final unconfirmed = User.fromJson({
        'id': 'u1',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'email': 'x@example.com',
        'created_at': '2024-01-01T00:00:00Z',
      });
      when(() => goTrue.currentUser).thenReturn(unconfirmed);
      final vm = makeVm(api: api, auth: auth, supabase: supabase);
      check(vm.isAlreadyAuthenticated).isFalse();
    });

    test('true when user has a confirmed email', () {
      final confirmed = User.fromJson({
        'id': 'u1',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'email': 'x@example.com',
        'email_confirmed_at': '2024-01-01T00:00:00Z',
        'created_at': '2024-01-01T00:00:00Z',
      });
      when(() => goTrue.currentUser).thenReturn(confirmed);
      final vm = makeVm(api: api, auth: auth, supabase: supabase);
      check(vm.isAlreadyAuthenticated).isTrue();
    });
  });

  // -------------------------------------------------------------------------
  // proceed()
  // -------------------------------------------------------------------------

  group('proceed()', () {
    test('no authenticated user: step becomes credentials', () async {
      when(() => api.getInvitationByToken(any()))
          .thenAnswer((_) async => testInvitation);
      when(() => goTrue.currentUser).thenReturn(null);

      final vm = makeVm(api: api, auth: auth, supabase: supabase);
      await vm.loadInvitation('test-token-uuid');
      await vm.proceed();

      check(vm.step).equals(JoinStep.credentials);
    });

    test('authenticated user with unconfirmed email: step becomes credentials',
        () async {
      when(() => api.getInvitationByToken(any()))
          .thenAnswer((_) async => testInvitation);
      final unconfirmedUser = User.fromJson({
        'id': 'user-1',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'email': 'tenant@example.com',
        'created_at': '2024-01-01T00:00:00Z',
        // no 'email_confirmed_at' key → null
      });
      when(() => goTrue.currentUser).thenReturn(unconfirmedUser);

      final vm = makeVm(api: api, auth: auth, supabase: supabase);
      await vm.loadInvitation('test-token-uuid');
      await vm.proceed();

      check(vm.step).equals(JoinStep.credentials);
    });

    test(
      'authenticated user with confirmed email: claims invitation directly',
      () async {
        final confirmedUser = User.fromJson({
          'id': 'user-1',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'email': 'tenant@example.com',
          'email_confirmed_at': '2024-01-01T00:00:00Z',
          'created_at': '2024-01-01T00:00:00Z',
        });
        when(() => api.getInvitationByToken(any()))
            .thenAnswer((_) async => testInvitation);
        when(() => goTrue.currentUser).thenReturn(confirmedUser);
        when(() => api.claimInvitation(
              userId: any(named: 'userId'),
              email: any(named: 'email'),
              housingId: any(named: 'housingId'),
              addressId: any(named: 'addressId'),
              phoneNumber: any(named: 'phoneNumber'),
            )).thenAnswer((_) async {});

        final vm = makeVm(api: api, auth: auth, supabase: supabase);
        await vm.loadInvitation('test-token-uuid');
        await vm.proceed();

        check(vm.step).equals(JoinStep.complete);
        verify(() => auth.joinComplete()).called(1);
        verify(() => api.claimInvitation(
              userId: 'user-1',
              email: 'tenant@example.com',
              housingId: testInvitation.address!.housingId,
              addressId: testInvitation.addressId,
              phoneNumber: null,
            )).called(1);
      },
    );
  });

  // -------------------------------------------------------------------------
  // submitCredentials() — validation (no Supabase calls made)
  // -------------------------------------------------------------------------

  group('submitCredentials() validation', () {
    late JoinViewModel vm;

    setUp(() async {
      when(() => api.getInvitationByToken(any()))
          .thenAnswer((_) async => testInvitation);
      when(() => goTrue.currentUser).thenReturn(null);
      vm = makeVm(api: api, auth: auth, supabase: supabase);
      await vm.loadInvitation('test-token-uuid');
      await vm.proceed(); // → credentials step
    });

    test('empty fields: sets emptyFields error, step unchanged', () async {
      await vm.submitCredentials('', '', '');

      check(vm.error).equals(JoinError.emptyFields);
      check(vm.step).equals(JoinStep.credentials);
    });

    test('password mismatch: sets passwordMismatch error', () async {
      await vm.submitCredentials('a@b.com', 'password1', 'password2');

      check(vm.error).equals(JoinError.passwordMismatch);
      check(vm.step).equals(JoinStep.credentials);
    });

    test('password too short: sets passwordTooShort error', () async {
      await vm.submitCredentials('a@b.com', 'short', 'short');

      check(vm.error).equals(JoinError.passwordTooShort);
      check(vm.step).equals(JoinStep.credentials);
    });

    test('validation errors do not call into Supabase auth', () async {
      await vm.submitCredentials('', '', '');

      verifyNever(() => goTrue.signUp(email: any(named: 'email'),
          password: any(named: 'password')));
    });
  });

  // -------------------------------------------------------------------------
  // dispose()
  // -------------------------------------------------------------------------

  group('dispose()', () {
    test('calls cancelJoin on authService', () async {
      when(() => api.getInvitationByToken(any()))
          .thenAnswer((_) async => testInvitation);

      final vm = makeVm(api: api, auth: auth, supabase: supabase);
      await vm.loadInvitation('test-token-uuid');

      verify(() => auth.beginJoin()).called(1);
      verifyNever(() => auth.cancelJoin());

      vm.dispose();

      verify(() => auth.cancelJoin()).called(1);
    });

    test('dispose after a failed load still calls cancelJoin', () async {
      when(() => api.getInvitationByToken(any()))
          .thenThrow(const InvitationNotFoundException());

      final vm = makeVm(api: api, auth: auth, supabase: supabase);
      await vm.loadInvitation('bad-token');

      // cancelJoin already called once during loadInvitation error handling.
      verify(() => auth.cancelJoin()).called(1);

      // dispose calls it again — that's fine, cancelJoin is idempotent.
      vm.dispose();
      verify(() => auth.cancelJoin()).called(1);
    });
  });
}
