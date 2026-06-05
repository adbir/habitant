import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:beboer_app/core/models/issue.dart';
import 'package:beboer_app/core/services/api_client.dart';
import 'package:beboer_app/features/staff/presentation/tenancy_issues_screen.dart';
import 'package:beboer_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Issue _issue({
  String id = 'issue-1',
  String description = 'Test issue description',
  IssueStatus status = IssueStatus.pending,
  String? assignedToName,
}) =>
    Issue(
      id: id,
      tenantId: 'tenant-1',
      addressId: 'address-1',
      housingId: 'housing-1',
      description: description,
      photoUrls: const [],
      status: status,
      needAssistance: false,
      assignedToName: assignedToName,
      updates: const [],
      comments: const [],
      createdAt: DateTime(2024, 3, 15),
    );

const _args = TenancyIssuesArgs(
  issueIds: ['issue-1', 'issue-2'],
  addressShortName: 'Testvej 1, 1 tv',
  tenantName: 'Lars Hansen',
);

// ---------------------------------------------------------------------------
// Test helper
// ---------------------------------------------------------------------------

Widget _buildScreen(MockApiClient api) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            TenancyIssuesScreen(args: _args, apiClient: api),
      ),
      GoRoute(
        path: '/staff/issues/:id',
        builder: (_, state) => Scaffold(
          body: Text('Issue detail: ${state.pathParameters['id']}'),
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
  late MockApiClient api;

  setUp(() {
    api = MockApiClient();
  });

  testWidgets('shows loading indicator while issues are being fetched',
      (tester) async {
    final completer = Completer<Issue>();
    when(() => api.getIssue(any())).thenAnswer((_) => completer.future);

    await tester.pumpWidget(_buildScreen(api));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_issue());
  });

  testWidgets('shows AppBar with tenant name and address', (tester) async {
    when(() => api.getIssue(any())).thenAnswer((_) async => _issue());

    await tester.pumpWidget(_buildScreen(api));
    await tester.pumpAndSettle();

    expect(find.text('Lars Hansen'), findsOneWidget);
    expect(find.text('Testvej 1, 1 tv'), findsOneWidget);
  });

  testWidgets('renders one card per loaded issue', (tester) async {
    when(() => api.getIssue('issue-1'))
        .thenAnswer((_) async => _issue(id: 'issue-1', description: 'Leaking radiator'));
    when(() => api.getIssue('issue-2'))
        .thenAnswer((_) async => _issue(id: 'issue-2', description: 'Broken window'));

    await tester.pumpWidget(_buildScreen(api));
    await tester.pumpAndSettle();

    expect(find.text('Leaking radiator'), findsOneWidget);
    expect(find.text('Broken window'), findsOneWidget);
  });

  testWidgets('shows assigned-to name when present', (tester) async {
    when(() => api.getIssue(any())).thenAnswer((_) async =>
        _issue(assignedToName: 'Thomas'));

    await tester.pumpWidget(_buildScreen(api));
    await tester.pumpAndSettle();

    expect(find.textContaining('Thomas'), findsWidgets);
  });

  testWidgets('shows error state when getIssue fails', (tester) async {
    when(() => api.getIssue(any()))
        .thenThrow(Exception('network error'));

    await tester.pumpWidget(_buildScreen(api));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Error state shows a retry button
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('tapping a card navigates to issue detail', (tester) async {
    when(() => api.getIssue(any()))
        .thenAnswer((_) async => _issue(id: 'issue-1'));

    await tester.pumpWidget(_buildScreen(api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test issue description').first);
    await tester.pumpAndSettle();

    expect(find.text('Issue detail: issue-1'), findsOneWidget);
  });
}
