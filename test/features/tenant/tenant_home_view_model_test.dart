import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:beboer_app/core/models/address.dart';
import 'package:beboer_app/core/models/housing.dart';
import 'package:beboer_app/core/models/issue.dart';
import 'package:beboer_app/core/models/tenant_profile.dart';
import 'package:beboer_app/core/services/api_client.dart';
import 'package:beboer_app/features/tenant/presentation/tenant_home_view_model.dart';

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

Issue _issue({String id = 'issue-1', String addressId = 'address-1'}) => Issue(
      id: id,
      tenantId: 'tenant-1',
      addressId: addressId,
      housingId: 'housing-1',
      description: 'Test issue',
      photoUrls: const [],
      status: IssueStatus.pending,
      needAssistance: false,
      updates: const [],
      comments: const [],
      createdAt: DateTime(2024, 1, 1),
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
  // currentHousingId and currentAddressId are null → moved out
);

final _newUserProfile = TenantProfile(
  id: 'tenant-1',
  email: 'tenant@example.com',
  createdAt: DateTime(2025, 1, 1),
);

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

TenantHomeViewModel _makeVm(MockApiClient api, MockAuthService auth) =>
    TenantHomeViewModel(apiClient: api, authService: auth);

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

  group('load() — onboarded tenant', () {
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

    test('populates housing, address, and issues', () async {
      final vm = _makeVm(api, auth);
      await vm.load();

      check(vm.housing).equals(_housing);
      check(vm.address).equals(_address);
      check(vm.issues).length.equals(1);
    });

    test('isLoading is false after success', () async {
      final vm = _makeVm(api, auth);
      await vm.load();
      check(vm.isLoading).isFalse();
    });

    test('isFormerTenant is false', () async {
      final vm = _makeVm(api, auth);
      await vm.load();
      check(vm.isFormerTenant).isFalse();
    });

    test('calls getTenantAllIssues, not getTenantIssues', () async {
      final vm = _makeVm(api, auth);
      await vm.load();

      verify(() => api.getTenantAllIssues('tenant-1')).called(1);
      verifyNever(() => api.getTenantIssues(any(), any()));
    });
  });

  group('load() — former tenant (moved out, has issues)', () {
    setUp(() {
      when(() => api.getTenantProfile('tenant-1'))
          .thenAnswer((_) async => _formerTenantProfile);
      when(() => api.getTenantAllIssues('tenant-1'))
          .thenAnswer((_) async => [
                _issue(id: 'old-1', addressId: 'old-address'),
                _issue(id: 'old-2', addressId: 'old-address'),
              ]);
    });

    test('issues are populated', () async {
      final vm = _makeVm(api, auth);
      await vm.load();
      check(vm.issues).length.equals(2);
    });

    test('address and housing are null', () async {
      final vm = _makeVm(api, auth);
      await vm.load();
      check(vm.address).isNull();
      check(vm.housing).isNull();
    });

    test('isFormerTenant is true', () async {
      final vm = _makeVm(api, auth);
      await vm.load();
      check(vm.isFormerTenant).isTrue();
    });

    test('does not call getHousing or getAddress', () async {
      final vm = _makeVm(api, auth);
      await vm.load();
      verifyNever(() => api.getHousing(any()));
      verifyNever(() => api.getAddress(any(), any()));
    });
  });

  group('load() — new user (not onboarded, no issues)', () {
    setUp(() {
      when(() => api.getTenantProfile('tenant-1'))
          .thenAnswer((_) async => _newUserProfile);
      when(() => api.getTenantAllIssues('tenant-1'))
          .thenAnswer((_) async => []);
    });

    test('issues are empty', () async {
      final vm = _makeVm(api, auth);
      await vm.load();
      check(vm.issues).isEmpty();
    });

    test('isFormerTenant is false', () async {
      final vm = _makeVm(api, auth);
      await vm.load();
      check(vm.isFormerTenant).isFalse();
    });

    test('address is null', () async {
      final vm = _makeVm(api, auth);
      await vm.load();
      check(vm.address).isNull();
    });
  });

  group('load() — API error', () {
    test('hasError is true, isLoading is false', () async {
      when(() => api.getTenantProfile(any()))
          .thenThrow(Exception('network error'));

      final vm = _makeVm(api, auth);
      await vm.load();

      check(vm.hasError).isTrue();
      check(vm.isLoading).isFalse();
    });

    test('no tenant ID: hasError is true', () async {
      when(() => auth.tenantId).thenReturn(null);

      final vm = _makeVm(api, auth);
      await vm.load();

      check(vm.hasError).isTrue();
    });
  });

  group('refresh()', () {
    test('clears error and reloads', () async {
      when(() => api.getTenantProfile(any()))
          .thenThrow(Exception('network error'));
      final vm = _makeVm(api, auth);
      await vm.load();
      check(vm.hasError).isTrue();

      when(() => api.getTenantProfile('tenant-1'))
          .thenAnswer((_) async => _onboardedProfile);
      when(() => api.getHousing('housing-1'))
          .thenAnswer((_) async => _housing);
      when(() => api.getAddress('housing-1', 'address-1'))
          .thenAnswer((_) async => _address);
      when(() => api.getTenantAllIssues('tenant-1'))
          .thenAnswer((_) async => []);

      await vm.refresh();

      check(vm.hasError).isFalse();
    });
  });
}
