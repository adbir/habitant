import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:beboer_app/core/models/address.dart';
import 'package:beboer_app/core/models/housing.dart';
import 'package:beboer_app/core/models/tenant_profile.dart';
import 'package:beboer_app/core/services/api_client.dart';
import 'package:beboer_app/features/tenant/presentation/tenant_profile_view_model.dart';

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
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient api;
  late MockAuthService auth;

  TenantProfileViewModel makeVm() => TenantProfileViewModel(
        apiClient: api,
        authService: auth,
      );

  setUp(() {
    api = MockApiClient();
    auth = MockAuthService();
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
    });

    test('profile, housing, and address are populated', () async {
      final vm = makeVm();
      await vm.load();

      check(vm.profile).equals(_onboardedProfile);
      check(vm.housing).equals(_housing);
      check(vm.address).equals(_address);
    });

    test('isLoading is false after success', () async {
      final vm = makeVm();
      await vm.load();
      check(vm.isLoading).isFalse();
    });

    test('hasError is false after success', () async {
      final vm = makeVm();
      await vm.load();
      check(vm.hasError).isFalse();
    });

    test('getAddress is called with housing and address IDs from profile',
        () async {
      final vm = makeVm();
      await vm.load();
      verify(() => api.getAddress('housing-1', 'address-1')).called(1);
    });
  });

  group('load() — not onboarded tenant', () {
    setUp(() {
      when(() => api.getTenantProfile('tenant-1'))
          .thenAnswer((_) async => _notOnboardedProfile);
    });

    test('profile is populated', () async {
      final vm = makeVm();
      await vm.load();
      check(vm.profile).equals(_notOnboardedProfile);
    });

    test('housing and address remain null', () async {
      final vm = makeVm();
      await vm.load();
      check(vm.housing).isNull();
      check(vm.address).isNull();
    });

    test('getHousing and getAddress are never called', () async {
      final vm = makeVm();
      await vm.load();
      verifyNever(() => api.getHousing(any()));
      verifyNever(() => api.getAddress(any(), any()));
    });
  });

  group('load() — error', () {
    test('hasError is true when getTenantProfile throws', () async {
      when(() => api.getTenantProfile(any()))
          .thenThrow(ApiException(500, 'Server error'));
      final vm = makeVm();
      await vm.load();
      check(vm.hasError).isTrue();
      check(vm.isLoading).isFalse();
    });

    test('hasError is true when getHousing throws', () async {
      when(() => api.getTenantProfile('tenant-1'))
          .thenAnswer((_) async => _onboardedProfile);
      when(() => api.getHousing(any()))
          .thenThrow(ApiException(503, 'Unavailable'));
      when(() => api.getAddress(any(), any()))
          .thenAnswer((_) async => _address);
      final vm = makeVm();
      await vm.load();
      check(vm.hasError).isTrue();
    });
  });

  group('load() — isLoading lifecycle', () {
    test('isLoading starts true and ends false', () async {
      when(() => api.getTenantProfile('tenant-1'))
          .thenAnswer((_) async => _notOnboardedProfile);
      final vm = makeVm();
      check(vm.isLoading).isTrue();
      await vm.load();
      check(vm.isLoading).isFalse();
    });
  });
}
