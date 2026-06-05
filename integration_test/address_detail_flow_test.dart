/// Integration test: address detail → tenancy issues → issue detail.
///
/// Bootstraps a minimal GoRouter app using [FakeApiClient] seed data so the
/// test runs entirely offline, without a real Supabase instance.  The auth
/// layer is bypassed by starting the router directly at [AddressDetailScreen].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:beboer_app/core/models/address.dart';
import 'package:beboer_app/dev/fake_api_client.dart';
import 'package:beboer_app/features/staff/presentation/address_detail_screen.dart';
import 'package:beboer_app/features/staff/presentation/tenancy_issues_screen.dart';
import 'package:beboer_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Known IDs from FakeApiClient seed data
// ---------------------------------------------------------------------------

const _housingId = '6ba7b810-9dad-41d1-80b4-00c04fd430c1';
const _addressId = 'a3bb189e-8bf9-4888-9912-ace4e6543001';
const _idLars = '550e8400-e29b-41d4-a716-446655440001';
const _radiatorIssueId = 'f47ac10b-58cc-4372-a567-0e02b2c3d101';
const _moldIssueId = 'f47ac10b-58cc-4372-a567-0e02b2c3d102';
const _windowIssueId = 'f47ac10b-58cc-4372-a567-0e02b2c3d103';

/// Address object that matches the Lars seed entry in [FakeApiClient].
/// Passed as [AddressDetailScreen.initialAddress] so the VM can request the
/// right data from the fake API.
final _larsAddress = Address(
  id: _addressId,
  housingId: _housingId,
  street: 'Rentemestervej',
  number: '23',
  floor: '1',
  side: 'tv',
  postalCode: '2400',
  city: 'København NV',
  isOccupied: true,
  history: [
    TenancyRecord(
      tenantId: _idLars,
      movedInAt: DateTime(2023, 3, 1),
      issueIds: [_radiatorIssueId, _moldIssueId, _windowIssueId],
    ),
  ],
);

// ---------------------------------------------------------------------------
// Test app
// ---------------------------------------------------------------------------

Widget _buildApp(FakeApiClient api) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => AddressDetailScreen(
          initialAddress: _larsAddress,
          apiClient: api,
        ),
      ),
      GoRoute(
        path: '/admin/housing/:housingId/address/:addressId/tenancy-issues',
        builder: (_, state) => TenancyIssuesScreen(
          args: state.extra as TenancyIssuesArgs,
          apiClient: api,
        ),
      ),
      // Stub — IssueDetailScreen requires AuthService which depends on Supabase.
      // We verify navigation succeeded by checking the route param in the title.
      GoRoute(
        path: '/staff/issues/:id',
        builder: (_, state) => Scaffold(
          appBar: AppBar(
            title: Text('issue:${state.pathParameters['id']}'),
          ),
          body: const SizedBox(),
        ),
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'shows loading spinner, then tenant history with tappable issues row',
    (tester) async {
      await tester.pumpWidget(_buildApp(FakeApiClient()));

      // Spinner visible immediately while data loads
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for all FakeApiClient delays (800 ms per call, ~2 s total)
      await tester.pumpAndSettle();

      // Lars appears in the history section (and in current-tenant section)
      expect(find.text('Lars Hansen'), findsWidgets);

      // A chevron-right icon marks the history row as tappable
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    },
  );

  testWidgets(
    'tapping history tile navigates to TenancyIssuesScreen',
    (tester) async {
      await tester.pumpWidget(_buildApp(FakeApiClient()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // TenancyIssuesScreen AppBar shows Lars's name
      expect(find.text('Lars Hansen'), findsOneWidget);

      // Address short name visible as subtitle
      expect(find.textContaining('Rentemestervej'), findsOneWidget);
    },
  );

  testWidgets(
    'TenancyIssuesScreen loads all three seed issues',
    (tester) async {
      await tester.pumpWidget(_buildApp(FakeApiClient()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Radiator issue description (matches first line of seed data)
      expect(
        find.textContaining('Radiator i soveværelset'),
        findsOneWidget,
      );

      // Mold issue
      expect(
        find.textContaining('Kraftig skimmelsvamp'),
        findsOneWidget,
      );

      // Window issue — verify three cards rendered
      expect(find.byType(Card), findsNWidgets(3));
    },
  );

  testWidgets(
    'tapping an issue card navigates to issue detail',
    (tester) async {
      await tester.pumpWidget(_buildApp(FakeApiClient()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Tap the radiator issue card
      await tester.tap(find.textContaining('Radiator i soveværelset'));
      await tester.pumpAndSettle();

      // Stub screen title encodes the issue ID
      expect(find.text('issue:$_radiatorIssueId'), findsOneWidget);
    },
  );
}
