import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:beboer_app/core/models/address.dart';
import 'package:beboer_app/core/models/issue.dart';
import 'package:beboer_app/core/models/issue_comment.dart';
import 'package:beboer_app/core/services/api_client.dart';
import 'package:beboer_app/features/tenant/presentation/tenant_issue_detail_screen.dart';
import 'package:beboer_app/l10n/app_localizations.dart';

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
  floor: '1',
  side: 'tv',
  postalCode: '2400',
  city: 'København NV',
  isOccupied: true,
  history: const [],
);

IssueComment _comment({
  String id = 'c-1',
  String body = 'Test comment body',
  bool isPrivate = false,
  String? authorName,
}) =>
    IssueComment(
      id: id,
      authorId: 'author-1',
      authorName: authorName,
      body: body,
      isPrivate: isPrivate,
      createdAt: DateTime(2024, 3, 15, 10),
    );

Issue _issue({
  List<IssueComment> comments = const [],
  List<String> photoUrls = const [],
  IssueStatus status = IssueStatus.pending,
  String? alternativeContactPhone,
}) =>
    Issue(
      id: 'issue-1',
      tenantId: 'tenant-1',
      addressId: 'address-1',
      housingId: 'housing-1',
      description: 'Leaking radiator in bedroom',
      photoUrls: photoUrls,
      status: status,
      needAssistance: false,
      alternativeContactPhone: alternativeContactPhone,
      updates: const [],
      comments: comments,
      createdAt: DateTime(2024, 3, 15),
    );

// ---------------------------------------------------------------------------
// Test helper
// ---------------------------------------------------------------------------

Widget _buildScreen(MockApiClient api, Issue issue) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: TenantIssueDetailScreen(apiClient: api, issue: issue),
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

  group('issue content', () {
    testWidgets('shows description', (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);

      await tester.pumpWidget(_buildScreen(api, _issue()));
      await tester.pumpAndSettle();

      expect(find.text('Leaking radiator in bedroom'), findsOneWidget);
    });

    testWidgets('shows pending status chip', (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);

      await tester.pumpWidget(_buildScreen(api, _issue()));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('shows inProgress status chip', (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);

      await tester.pumpWidget(
          _buildScreen(api, _issue(status: IssueStatus.inProgress)));
      await tester.pumpAndSettle();

      expect(find.text('In progress'), findsOneWidget);
    });

    testWidgets('shows completed status chip', (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);

      await tester.pumpWidget(
          _buildScreen(api, _issue(status: IssueStatus.completed)));
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
    });
  });

  group('comments visibility — privacy filter', () {
    testWidgets('shows public comment', (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);
      final issue = _issue(comments: [
        _comment(body: 'Maintenance coming Thursday', isPrivate: false),
      ]);

      await tester.pumpWidget(_buildScreen(api, issue));
      await tester.pumpAndSettle();

      expect(find.text('Maintenance coming Thursday'), findsOneWidget);
    });

    testWidgets('hides private (staff-only) comment', (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);
      final issue = _issue(comments: [
        _comment(body: 'Internal: check boiler too', isPrivate: true),
      ]);

      await tester.pumpWidget(_buildScreen(api, issue));
      await tester.pumpAndSettle();

      expect(find.text('Internal: check boiler too'), findsNothing);
    });

    testWidgets(
        'shows public comment but not private when both present',
        (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);
      final issue = _issue(comments: [
        _comment(id: 'c-1', body: 'Technician scheduled', isPrivate: false),
        _comment(id: 'c-2', body: 'Internal note: budget approved', isPrivate: true),
      ]);

      await tester.pumpWidget(_buildScreen(api, issue));
      await tester.pumpAndSettle();

      expect(find.text('Technician scheduled'), findsOneWidget);
      expect(find.text('Internal note: budget approved'), findsNothing);
    });

    testWidgets('shows no-comments message when all comments are private',
        (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);
      final issue = _issue(comments: [
        _comment(body: 'Staff-only note', isPrivate: true),
      ]);

      await tester.pumpWidget(_buildScreen(api, issue));
      await tester.pumpAndSettle();

      expect(find.text('No comments yet'), findsOneWidget);
    });

    testWidgets('shows no-comments message when issue has no comments',
        (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);

      await tester.pumpWidget(_buildScreen(api, _issue()));
      await tester.pumpAndSettle();

      expect(find.text('No comments yet'), findsOneWidget);
    });
  });

  group('no comment input', () {
    testWidgets('no TextField is rendered', (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);

      await tester.pumpWidget(_buildScreen(api, _issue()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('no send button is rendered', (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);

      await tester.pumpWidget(_buildScreen(api, _issue()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.send), findsNothing);
    });
  });

  group('address loading', () {
    testWidgets('shows loading spinner while address is fetching',
        (tester) async {
      final completer = Completer<Address>();
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(_buildScreen(api, _issue()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(_address);
    });

    testWidgets('shows address after loading completes', (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);

      await tester.pumpWidget(_buildScreen(api, _issue()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Testvej 1'), findsOneWidget);
    });

    testWidgets('falls back to addressId when getAddress fails',
        (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenThrow(Exception('network error'));

      await tester.pumpWidget(_buildScreen(api, _issue()));
      await tester.pumpAndSettle();

      expect(find.text('address-1'), findsOneWidget);
    });
  });

  group('photos section', () {
    testWidgets('photos row is absent when issue has no photos', (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);

      await tester.pumpWidget(_buildScreen(api, _issue(photoUrls: [])));
      await tester.pumpAndSettle();

      // No horizontal ListView (photos) should be present.
      expect(
        find.byWidgetPredicate((w) =>
            w is ListView && w.scrollDirection == Axis.horizontal),
        findsNothing,
      );
    });
  });

  group('alternative contact phone', () {
    testWidgets('shows alternative phone when present', (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);

      await tester.pumpWidget(_buildScreen(
        api,
        _issue(alternativeContactPhone: '+45 12 34 56 78'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('+45 12 34 56 78'), findsOneWidget);
    });

    testWidgets('phone row absent when no alternative phone', (tester) async {
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);

      await tester.pumpWidget(_buildScreen(api, _issue()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.phone_outlined), findsNothing);
    });
  });
}
