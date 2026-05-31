import 'package:mocktail/mocktail.dart';

import 'package:beboer_app/core/services/auth_service.dart';

/// Mocktail mock of [AuthService].
///
/// Use [verify] to assert call counts, e.g.:
/// ```dart
/// verify(() => auth.beginJoin()).called(1);
/// verifyNever(() => auth.cancelJoin());
/// ```
///
/// Default stubs for the most-used methods are applied by [stubDefaults].
/// Call this in your [setUp] after creating the instance.
class MockAuthService extends Mock implements AuthService {}

/// Applies sensible defaults to [mock] so tests don't fail on unstubbed calls.
///
/// Override individual stubs in your test body as needed.
void stubAuthServiceDefaults(MockAuthService mock) {
  when(() => mock.beginJoin()).thenReturn(null);
  when(() => mock.cancelJoin()).thenReturn(null);
  when(() => mock.joinComplete()).thenAnswer((_) async {});
  when(() => mock.signupComplete()).thenAnswer((_) async {});
  when(() => mock.joinInProgress).thenReturn(false);
  when(() => mock.isAuthenticated).thenReturn(false);
  when(() => mock.tenantId).thenReturn(null);
}
