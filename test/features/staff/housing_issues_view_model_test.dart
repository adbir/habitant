import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:beboer_app/core/models/issue.dart';
import 'package:beboer_app/core/models/paged_result.dart';
import 'package:beboer_app/core/services/api_client.dart';
import 'package:beboer_app/features/staff/presentation/housing_issues_view_model.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Issue _issue(String id, {IssueStatus status = IssueStatus.pending}) => Issue(
      id: id,
      tenantId: 't1',
      addressId: 'a1',
      housingId: 'h1',
      description: 'Test issue $id',
      status: status,
      needAssistance: false,
      photoUrls: const [],
      updates: const [],
      comments: const [],
      createdAt: DateTime(2024),
    );

PagedResult<Issue> _page(
  List<Issue> items, {
  bool hasMore = false,
}) =>
    PagedResult(items: items, hasMore: hasMore);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Stubs [mock.getHousingIssues] to return [result] for any arguments.
void _stubIssues(MockApiClient mock, PagedResult<Issue> result) {
  when(
    () => mock.getHousingIssues(
      any(),
      statuses: any(named: 'statuses'),
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
    ),
  ).thenAnswer((_) async => result);
}

/// Stubs [mock.getHousingIssues] to throw [error] for any arguments.
void _stubIssuesError(MockApiClient mock, Object error) {
  when(
    () => mock.getHousingIssues(
      any(),
      statuses: any(named: 'statuses'),
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
    ),
  ).thenThrow(error);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient api;

  setUp(() {
    api = MockApiClient();
  });

  HousingIssuesViewModel makeVm() => HousingIssuesViewModel(
        apiClient: api,
        housingId: 'h1',
      );

  // -------------------------------------------------------------------------
  // load()
  // -------------------------------------------------------------------------

  group('load()', () {
    test('success: issues populated, isLoading false, hasMore set', () async {
      _stubIssues(
        api,
        _page([_issue('i1'), _issue('i2')], hasMore: true),
      );

      final vm = makeVm();
      await vm.load();

      check(vm.issues).length.equals(2);
      check(vm.hasMore).isTrue();
      check(vm.isLoading).isFalse();
      check(vm.hasError).isFalse();
    });

    test('success: hasMore false when no further pages', () async {
      _stubIssues(api, _page([_issue('i1')]));

      final vm = makeVm();
      await vm.load();

      check(vm.hasMore).isFalse();
    });

    test('API error: hasError true, issues empty', () async {
      _stubIssuesError(api, Exception('network error'));

      final vm = makeVm();
      await vm.load();

      check(vm.hasError).isTrue();
      check(vm.issues).isEmpty();
    });

    test('isLoading is false after success', () async {
      _stubIssues(api, _page([_issue('i1')]));

      final vm = makeVm();
      await vm.load();

      check(vm.isLoading).isFalse();
    });

    test('isLoading is false after error', () async {
      _stubIssuesError(api, Exception('network error'));

      final vm = makeVm();
      await vm.load();

      check(vm.isLoading).isFalse();
    });
  });

  // -------------------------------------------------------------------------
  // loadMore()
  // -------------------------------------------------------------------------

  group('loadMore()', () {
    test('success: appends issues, increments page, updates hasMore', () async {
      // First page: two issues, more available.
      when(
        () => api.getHousingIssues(
          any(),
          statuses: any(named: 'statuses'),
          page: 0,
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => _page([_issue('i1'), _issue('i2')], hasMore: true),
      );
      // Second page: one issue, no more.
      when(
        () => api.getHousingIssues(
          any(),
          statuses: any(named: 'statuses'),
          page: 1,
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => _page([_issue('i3')]),
      );

      final vm = makeVm();
      await vm.load();
      check(vm.issues).length.equals(2);

      await vm.loadMore();

      check(vm.issues).length.equals(3);
      check(vm.issues.last.id).equals('i3');
      check(vm.hasMore).isFalse();
      check(vm.isLoadingMore).isFalse();
    });

    test('no-op when hasMore is false', () async {
      _stubIssues(api, _page([_issue('i1')], hasMore: false));

      final vm = makeVm();
      await vm.load();

      await vm.loadMore();

      // getHousingIssues should only have been called once (from load).
      verify(
        () => api.getHousingIssues(
          any(),
          statuses: any(named: 'statuses'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).called(1);
    });

    test('no-op when isLoadingMore is already true', () async {
      _stubIssues(api, _page([_issue('i1')], hasMore: true));

      final vm = makeVm();
      await vm.load();

      // Simulate concurrent guard by calling loadMore twice without await.
      // The second call should be a no-op because isLoadingMore is true.
      var callCount = 0;
      when(
        () => api.getHousingIssues(
          any(),
          statuses: any(named: 'statuses'),
          page: 1,
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        return _page([_issue('i2')]);
      });

      final first = vm.loadMore();
      // isLoadingMore is true before first completes — second should bail.
      final second = vm.loadMore();
      await Future.wait([first, second]);

      check(callCount).equals(1);
    });
  });

  // -------------------------------------------------------------------------
  // refresh()
  // -------------------------------------------------------------------------

  group('refresh()', () {
    test('resets to page 0 and reloads', () async {
      // First load: page 0, two issues with more available.
      when(
        () => api.getHousingIssues(
          any(),
          statuses: any(named: 'statuses'),
          page: 0,
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => _page([_issue('i1'), _issue('i2')], hasMore: true),
      );
      // Page 1 for loadMore.
      when(
        () => api.getHousingIssues(
          any(),
          statuses: any(named: 'statuses'),
          page: 1,
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => _page([_issue('i3')]),
      );

      final vm = makeVm();
      await vm.load();
      await vm.loadMore();
      check(vm.issues).length.equals(3);

      // After refresh, issues reset to first-page result only.
      await vm.refresh();

      check(vm.issues).length.equals(2);
      check(vm.hasMore).isTrue();
      check(vm.isLoading).isFalse();
    });
  });
}
