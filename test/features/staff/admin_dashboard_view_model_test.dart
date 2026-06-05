import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:beboer_app/core/models/address.dart';
import 'package:beboer_app/core/models/housing.dart';
import 'package:beboer_app/core/models/issue.dart';
import 'package:beboer_app/core/models/paged_result.dart';
import 'package:beboer_app/core/services/api_client.dart';
import 'package:beboer_app/features/staff/presentation/admin_dashboard_view_model.dart';

import '../../helpers/fake_auth_service.dart';

// ---------------------------------------------------------------------------
// Mocks & fixtures
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

Address _address({required String id, required String housingId, bool occupied = false}) =>
    Address(
      id: id,
      housingId: housingId,
      street: 'Testvej',
      number: '1',
      postalCode: '2400',
      city: 'København',
      isOccupied: occupied,
      history: const [],
    );

Housing _housing(String id, List<Address> addresses) => Housing(
      id: id,
      name: 'Test Housing $id',
      city: 'København',
      addresses: addresses,
      createdAt: DateTime(2024),
    );

Issue _issue(String id, IssueStatus status) => Issue(
      id: id,
      tenantId: 'tenant-1',
      addressId: 'addr-1',
      housingId: 'h1',
      description: 'Test issue',
      status: status,
      needAssistance: false,
      photoUrls: const [],
      updates: const [],
      comments: const [],
      createdAt: DateTime(2024),
    );

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
    when(() => auth.tenantId).thenReturn('staff-id');
  });

  AdminDashboardViewModel makeVm() => AdminDashboardViewModel(
        apiClient: api,
        authService: auth,
      );

  group('load()', () {
    test('success: housings and counts are populated', () async {
      final h1 = _housing('h1', [
        _address(id: 'a1', housingId: 'h1', occupied: true),
        _address(id: 'a2', housingId: 'h1'),
      ]);
      final h2 = _housing('h2', [
        _address(id: 'a3', housingId: 'h2'),
      ]);
      when(() => api.getStaffHousings(any())).thenAnswer((_) async => [h1, h2]);
      when(
        () => api.getHousingIssues(
          'h1',
          statuses: any(named: 'statuses'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [
            _issue('i1', IssueStatus.pending),
            _issue('i2', IssueStatus.completed), // excluded
          ],
          hasMore: false,
        ),
      );
      when(
        () => api.getHousingIssues(
          'h2',
          statuses: any(named: 'statuses'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => const PagedResult(items: [], hasMore: false),
      );

      final vm = makeVm();
      await vm.load();

      check(vm.housings).length.equals(2);
      check(vm.openIssueCountFor('h1')).equals(1);
      check(vm.openIssueCountFor('h2')).equals(0);
      check(vm.hasError).isFalse();
    });

    test('API error: hasError is true, housings empty', () async {
      when(() => api.getStaffHousings(any()))
          .thenThrow(Exception('network error'));

      final vm = makeVm();
      await vm.load();

      check(vm.hasError).isTrue();
      check(vm.housings).isEmpty();
    });

    test('isLoading is false after completion', () async {
      when(() => api.getStaffHousings(any())).thenAnswer((_) async => []);

      final vm = makeVm();
      await vm.load();

      check(vm.isLoading).isFalse();
    });

    test('refresh() calls load() and resets error', () async {
      when(() => api.getStaffHousings(any()))
          .thenThrow(Exception('first call fails'));

      final vm = makeVm();
      await vm.load();
      check(vm.hasError).isTrue();

      when(() => api.getStaffHousings(any())).thenAnswer((_) async => []);
      await vm.refresh();

      check(vm.hasError).isFalse();
    });
  });

  group('derived stats', () {
    late AdminDashboardViewModel vm;

    setUp(() async {
      final h1 = _housing('h1', [
        _address(id: 'a1', housingId: 'h1', occupied: true),
        _address(id: 'a2', housingId: 'h1'),
      ]);
      final h2 = _housing('h2', [
        _address(id: 'a3', housingId: 'h2'),
      ]);
      when(() => api.getStaffHousings(any())).thenAnswer((_) async => [h1, h2]);
      when(
        () => api.getHousingIssues(
          any(),
          statuses: any(named: 'statuses'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => const PagedResult(items: [], hasMore: false),
      );

      vm = makeVm();
      await vm.load();
    });

    test('totalAddresses counts all addresses', () {
      check(vm.totalAddresses).equals(3);
    });

    test('totalOccupied counts occupied addresses', () {
      check(vm.totalOccupied).equals(1);
    });

    test('totalVacant = totalAddresses - totalOccupied', () {
      check(vm.totalVacant).equals(2);
    });

    test('openIssueCountFor returns 0 for unknown housingId', () {
      check(vm.openIssueCountFor('unknown')).equals(0);
    });
  });

  group('openIssueCountFor excludes completed and rejected', () {
    test('all terminal statuses are excluded', () async {
      final h = _housing('h1', [_address(id: 'a1', housingId: 'h1')]);
      when(() => api.getStaffHousings(any())).thenAnswer((_) async => [h]);
      when(
        () => api.getHousingIssues(
          'h1',
          statuses: any(named: 'statuses'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => PagedResult(
          items: [
            _issue('i1', IssueStatus.pending),
            _issue('i2', IssueStatus.assigned),
            _issue('i3', IssueStatus.inProgress),
            _issue('i4', IssueStatus.completed), // excluded
            _issue('i5', IssueStatus.rejected), // excluded
          ],
          hasMore: false,
        ),
      );

      final vm = makeVm();
      await vm.load();

      check(vm.openIssueCountFor('h1')).equals(3);
    });
  });
}
