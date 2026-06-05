import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:beboer_app/core/models/address.dart';
import 'package:beboer_app/core/models/housing.dart';
import 'package:beboer_app/core/models/issue.dart';
import 'package:beboer_app/core/models/tenant_profile.dart';
import 'package:beboer_app/core/services/api_client.dart';
import 'package:beboer_app/features/tenant/presentation/tenant_home_screen.dart';
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

Issue _issue({String id = 'issue-1'}) => Issue(
      id: id,
      tenantId: 'tenant-1',
      addressId: 'address-1',
      housingId: 'housing-1',
      description: 'Leaking pipe',
      photoUrls: const [],
      status: IssueStatus.completed,
      needAssistance: false,
      updates: const [],
      comments: const [],
      createdAt: DateTime(2023, 6, 1),
    );

final _onboardedProfile = TenantProfile(
  id: 'tenant-1',
  email: 'tenant@example.com',
  currentHousingId: 'housing-1',
  currentAddressId: 'address-1',
  createdAt: DateTime(2023, 1, 1),
);

final _formerTenantProfile = TenantProfile(
  id: 'tenant-1',
  email: 'tenant@example.com',
  createdAt: DateTime(2021, 1, 1),
);

final _newUserProfile = TenantProfile(
  id: 'tenant-1',
  email: 'tenant@example.com',
  createdAt: DateTime(2025, 1, 1),
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
            TenantHomeScreen(apiClient: api, authService: auth),
      ),
      GoRoute(
        path: '/tenant/issues/:id',
        builder: (_, state) => Scaffold(
          body: Text('Issue: ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/tenant/report-issue',
        builder: (_, _) => const Scaffold(body: Text('Report issue')),
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
    stubAuthServiceDefaults(auth);
    when(() => auth.tenantId).thenReturn('tenant-1');
  });

  group('former tenant state', () {
    setUp(() {
      when(() => api.getTenantProfile('tenant-1'))
          .thenAnswer((_) async => _formerTenantProfile);
      when(() => api.getTenantAllIssues('tenant-1'))
          .thenAnswer((_) async => [_issue()]);
    });

    testWidgets('shows former-tenant banner', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();

      expect(find.text("You've moved out"), findsOneWidget);
    });

    testWidgets('shows past issues', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();

      expect(find.text('Leaking pipe'), findsOneWidget);
    });

    testWidgets('no FAB — cannot report new issues', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  group('new user state (no housing, no issues)', () {
    setUp(() {
      when(() => api.getTenantProfile('tenant-1'))
          .thenAnswer((_) async => _newUserProfile);
      when(() => api.getTenantAllIssues('tenant-1'))
          .thenAnswer((_) async => []);
    });

    testWidgets('shows awaiting-invitation placeholder', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();

      expect(find.text('Awaiting assignment'), findsOneWidget);
    });

    testWidgets('no FAB', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('former-tenant banner is absent', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();

      expect(find.text("You've moved out"), findsNothing);
    });
  });

  group('onboarded tenant state', () {
    setUp(() {
      when(() => api.getTenantProfile('tenant-1'))
          .thenAnswer((_) async => _onboardedProfile);
      when(() => api.getHousing('housing-1'))
          .thenAnswer((_) async => _housing);
      when(() => api.getAddress('housing-1', 'address-1'))
          .thenAnswer((_) async => _address);
      when(() => api.getTenantAllIssues('tenant-1'))
          .thenAnswer((_) async => [_issue()]);
    });

    testWidgets('shows issue list', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();

      expect(find.text('Leaking pipe'), findsOneWidget);
    });

    testWidgets('shows FAB for reporting issues', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('former-tenant banner is absent', (tester) async {
      await tester.pumpWidget(_buildScreen(api, auth));
      await tester.pumpAndSettle();

      expect(find.text("You've moved out"), findsNothing);
    });
  });
}
