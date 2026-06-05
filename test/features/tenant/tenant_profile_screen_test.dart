import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:beboer_app/core/models/address.dart';
import 'package:beboer_app/core/models/housing.dart';
import 'package:beboer_app/core/models/tenant_profile.dart';
import 'package:beboer_app/core/services/api_client.dart';
import 'package:beboer_app/features/tenant/presentation/tenant_profile_screen.dart';
import 'package:beboer_app/l10n/app_localizations.dart';

import '../../helpers/fake_auth_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _address = Address(
  id: 'address-1',
  housingId: 'housing-1',
  street: 'Testvej',
  number: '1',
  postalCode: '2400',
  city: 'København NV',
  isOccupied: true,
  history: const [],
);

final _housing = Housing(
  id: 'housing-1',
  name: 'Test Housing',
  city: 'København NV',
  createdAt: DateTime(2020, 1, 1),
  addresses: [_address],
);

final _onboardedProfile = TenantProfile(
  id: 'tenant-1',
  email: 'tenant@example.com',
  name: 'Lars Hansen',
  phoneNumber: '12345678',
  currentHousingId: 'housing-1',
  currentAddressId: 'address-1',
  createdAt: DateTime(2023, 1, 1),
);

final _notOnboardedProfile = TenantProfile(
  id: 'tenant-1',
  email: 'tenant@example.com',
  createdAt: DateTime(2023, 1, 1),
);

// ---------------------------------------------------------------------------
// Test helper
// ---------------------------------------------------------------------------

Widget _buildScreen(MockApiClient api, MockAuthService auth) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            TenantProfileScreen(apiClient: api, authService: auth),
      ),
      GoRoute(
        path: '/tenant/claim-invitation',
        builder: (_, _) =>
            const Scaffold(body: Text('Claim invitation screen')),
      ),
      GoRoute(
        path: '/join',
        builder: (_, _) => const Scaffold(body: Text('Join screen')),
      ),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient api;
  late MockAuthService auth;

  setUp(() {
    api = MockApiClient();
    auth = MockAuthService();
    when(() => auth.tenantId).thenReturn('tenant-1');
  });

  group('loading state', () {
    testWidgets('shows loading indicator while data is being fetched',
        (tester) async {
      final completer = Completer<TenantProfile>();
      when(() => api.getTenantProfile(any()))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(_notOnboardedProfile);
    });
  });

  group('onboarded tenant', () {
    setUp(() {
      when(() => api.getTenantProfile('tenant-1'))
          .thenAnswer((_) async => _onboardedProfile);
      when(() => api.getHousing('housing-1'))
          .thenAnswer((_) async => _housing);
      when(() => api.getAddress('housing-1', 'address-1'))
          .thenAnswer((_) async => _address);
    });

    testWidgets('shows tenant name', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      expect(find.text('Lars Hansen'), findsOneWidget);
    });

    testWidgets('shows email', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      expect(find.text('tenant@example.com'), findsOneWidget);
    });

    testWidgets('shows phone number', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      expect(find.text('12345678'), findsOneWidget);
    });

    testWidgets('shows housing name in address section', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      expect(find.text('Test Housing'), findsOneWidget);
    });

    testWidgets('shows formatted address', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      expect(find.textContaining('Testvej'), findsOneWidget);
    });

    testWidgets('does not show "not linked" message', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      expect(find.text('Not linked to an address'), findsNothing);
    });

    testWidgets('claim invitation button is present', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      expect(find.text('Claim invitation'), findsOneWidget);
    });

    testWidgets('tapping claim invitation navigates to claim screen',
        (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Claim invitation'));
      await tester.pumpAndSettle();
      expect(find.text('Claim invitation screen'), findsOneWidget);
    });
  });

  group('not onboarded tenant', () {
    setUp(() {
      when(() => api.getTenantProfile('tenant-1'))
          .thenAnswer((_) async => _notOnboardedProfile);
    });

    testWidgets('shows "not linked" message', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      expect(find.text('Not linked to an address'), findsOneWidget);
    });

    testWidgets('does not show housing name', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      expect(find.text('Test Housing'), findsNothing);
    });

    testWidgets('claim invitation button is present', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      expect(find.text('Claim invitation'), findsOneWidget);
    });
  });

  group('error state', () {
    setUp(() {
      when(() => api.getTenantProfile(any()))
          .thenThrow(ApiException(500, 'Server error'));
    });

    testWidgets('shows error message', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      expect(find.text('Could not load your data. Please try again.'),
          findsOneWidget);
    });

    testWidgets('shows retry button', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
