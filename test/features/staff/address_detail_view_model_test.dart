import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:beboer_app/core/models/address.dart';
import 'package:beboer_app/core/models/invitation.dart';
import 'package:beboer_app/core/models/tenant_profile.dart';
import 'package:beboer_app/core/services/api_client.dart';
import 'package:beboer_app/features/staff/presentation/address_detail_view_model.dart';
import 'package:beboer_app/features/staff/presentation/housing_detail_view_model.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Address _address({
  required String id,
  required String housingId,
  bool occupied = false,
  List<TenancyRecord> history = const [],
}) =>
    Address(
      id: id,
      housingId: housingId,
      street: 'Testvej',
      number: '1',
      postalCode: '2400',
      city: 'København',
      isOccupied: occupied,
      history: history,
    );

TenancyRecord _record({
  required String tenantId,
  List<String> issueIds = const [],
  DateTime? movedOutAt,
}) =>
    TenancyRecord(
      tenantId: tenantId,
      movedInAt: DateTime(2023, 1, 1),
      movedOutAt: movedOutAt,
      issueIds: issueIds,
    );

Invitation _invitation(String addressId) => Invitation(
      id: 'inv-1',
      token: 'token-1',
      addressId: addressId,
      expiresAt: DateTime(2030),
    );

TenantProfile _profile(String id) => TenantProfile(
      id: id,
      email: '$id@example.com',
      name: 'Tenant $id',
      createdAt: DateTime(2023, 1, 1),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient api;

  setUp(() {
    api = MockApiClient();
    when(() => api.getAddressTenants(any())).thenAnswer((_) async => []);
    when(() => api.getHousingInvitations(any())).thenAnswer((_) async => []);
    when(() => api.getTenantProfile(any()))
        .thenAnswer((_) async => _profile('fallback'));
  });

  AddressDetailViewModel makeVm(Address address) =>
      AddressDetailViewModel(apiClient: api, address: address);

  // -------------------------------------------------------------------------
  // load()
  // -------------------------------------------------------------------------

  group('load()', () {
    test('success: current tenants and matching invitation populated', () async {
      final address = _address(id: 'a1', housingId: 'h1');
      when(() => api.getAddressTenants('a1'))
          .thenAnswer((_) async => [_profile('t1')]);
      when(() => api.getHousingInvitations('h1'))
          .thenAnswer((_) async => [_invitation('a1')]);

      final vm = makeVm(address);
      await vm.load();

      check(vm.currentTenants).length.equals(1);
      check(vm.invitation).isNotNull();
      check(vm.isLoading).isFalse();
      check(vm.hasError).isFalse();
    });

    test('success: invitation for a different address is ignored', () async {
      final address = _address(id: 'a1', housingId: 'h1');
      when(() => api.getHousingInvitations('h1'))
          .thenAnswer((_) async => [_invitation('a-other')]);

      final vm = makeVm(address);
      await vm.load();

      check(vm.invitation).isNull();
    });

    test('success: history tenant profiles available via profileFor()', () async {
      final address = _address(
        id: 'a1',
        housingId: 'h1',
        history: [_record(tenantId: 't-hist')],
      );
      when(() => api.getTenantProfile('t-hist'))
          .thenAnswer((_) async => _profile('t-hist'));

      final vm = makeVm(address);
      await vm.load();

      check(vm.profileFor('t-hist')).isNotNull();
    });

    test('profile silently missing when getTenantProfile throws 404', () async {
      final address = _address(
        id: 'a1',
        housingId: 'h1',
        history: [_record(tenantId: 't-missing')],
      );
      when(() => api.getTenantProfile('t-missing'))
          .thenAnswer((_) => Future.error(ApiException(404, 'not found')));

      final vm = makeVm(address);
      await vm.load();

      check(vm.hasError).isFalse();
      check(vm.profileFor('t-missing')).isNull();
    });

    test('profileFor returns null for unknown tenantId', () async {
      final vm = makeVm(_address(id: 'a1', housingId: 'h1'));
      await vm.load();

      check(vm.profileFor('nobody')).isNull();
    });

    test('API error: hasError true, isLoading false', () async {
      when(() => api.getAddressTenants(any()))
          .thenThrow(Exception('network error'));

      final vm = makeVm(_address(id: 'a1', housingId: 'h1'));
      await vm.load();

      check(vm.hasError).isTrue();
      check(vm.isLoading).isFalse();
    });
  });

  // -------------------------------------------------------------------------
  // status
  // -------------------------------------------------------------------------

  group('status', () {
    test('isOccupied=true → occupied regardless of invitations', () async {
      final address = _address(id: 'a1', housingId: 'h1', occupied: true);
      when(() => api.getHousingInvitations('h1'))
          .thenAnswer((_) async => [_invitation('a1')]);

      final vm = makeVm(address);
      await vm.load();

      check(vm.status).equals(AddressStatus.occupied);
    });

    test('unoccupied + matching invitation → invitationPending', () async {
      final address = _address(id: 'a1', housingId: 'h1');
      when(() => api.getHousingInvitations('h1'))
          .thenAnswer((_) async => [_invitation('a1')]);

      final vm = makeVm(address);
      await vm.load();

      check(vm.status).equals(AddressStatus.invitationPending);
    });

    test('unoccupied + no invitation → vacant', () async {
      final vm = makeVm(_address(id: 'a1', housingId: 'h1'));
      await vm.load();

      check(vm.status).equals(AddressStatus.vacant);
    });
  });

  // -------------------------------------------------------------------------
  // createInvitation()
  // -------------------------------------------------------------------------

  group('createInvitation()', () {
    test('success: invitation set, isCreatingInvitation resets to false',
        () async {
      final address = _address(id: 'a1', housingId: 'h1');
      final inv = _invitation('a1');
      when(() => api.createInvitation('a1')).thenAnswer((_) async => inv);

      final vm = makeVm(address);
      await vm.load();
      await vm.createInvitation();

      check(vm.invitation).equals(inv);
      check(vm.status).equals(AddressStatus.invitationPending);
      check(vm.isCreatingInvitation).isFalse();
      check(vm.hasError).isFalse();
    });

    test('isCreatingInvitation is true while in-flight', () async {
      final address = _address(id: 'a1', housingId: 'h1');
      final completer = Completer<Invitation>();
      when(() => api.createInvitation(any()))
          .thenAnswer((_) => completer.future);

      final vm = makeVm(address);
      await vm.load();

      final f = vm.createInvitation();
      check(vm.isCreatingInvitation).isTrue();
      completer.complete(_invitation('a1'));
      await f;
      check(vm.isCreatingInvitation).isFalse();
    });

    test('API error: hasError true, invitation stays null', () async {
      when(() => api.createInvitation(any()))
          .thenThrow(Exception('server error'));

      final vm = makeVm(_address(id: 'a1', housingId: 'h1'));
      await vm.load();
      await vm.createInvitation();

      check(vm.invitation).isNull();
      check(vm.hasError).isTrue();
    });
  });

  // -------------------------------------------------------------------------
  // cancelInvitation()
  // -------------------------------------------------------------------------

  group('cancelInvitation()', () {
    test('success: invitation cleared, status becomes vacant', () async {
      final address = _address(id: 'a1', housingId: 'h1');
      when(() => api.getHousingInvitations('h1'))
          .thenAnswer((_) async => [_invitation('a1')]);
      when(() => api.cancelInvitation('inv-1')).thenAnswer((_) async {});

      final vm = makeVm(address);
      await vm.load();
      check(vm.status).equals(AddressStatus.invitationPending);

      await vm.cancelInvitation();

      check(vm.invitation).isNull();
      check(vm.status).equals(AddressStatus.vacant);
      check(vm.isCancellingInvitation).isFalse();
    });

    test('isCancellingInvitation is true while in-flight', () async {
      final address = _address(id: 'a1', housingId: 'h1');
      when(() => api.getHousingInvitations('h1'))
          .thenAnswer((_) async => [_invitation('a1')]);

      final completer = Completer<void>();
      when(() => api.cancelInvitation(any()))
          .thenAnswer((_) => completer.future);

      final vm = makeVm(address);
      await vm.load();

      final f = vm.cancelInvitation();
      check(vm.isCancellingInvitation).isTrue();
      completer.complete();
      await f;
      check(vm.isCancellingInvitation).isFalse();
    });

    test('API error: invitation retained', () async {
      final address = _address(id: 'a1', housingId: 'h1');
      when(() => api.getHousingInvitations('h1'))
          .thenAnswer((_) async => [_invitation('a1')]);
      when(() => api.cancelInvitation(any()))
          .thenThrow(Exception('network error'));

      final vm = makeVm(address);
      await vm.load();
      await vm.cancelInvitation();

      check(vm.invitation).isNotNull();
    });

    test('no-op and no crash when there is no invitation', () async {
      final vm = makeVm(_address(id: 'a1', housingId: 'h1'));
      await vm.load();

      await vm.cancelInvitation(); // should not throw

      check(vm.invitation).isNull();
      verifyNever(() => api.cancelInvitation(any()));
    });
  });

  // -------------------------------------------------------------------------
  // invitationLink()
  // -------------------------------------------------------------------------

  group('invitationLink()', () {
    test('returns URL containing the invitation token', () {
      final vm = makeVm(_address(id: 'a1', housingId: 'h1'));
      final inv = _invitation('a1');
      final link = vm.invitationLink(inv);

      check(link).contains(inv.token);
      check(link).startsWith('https://');
    });
  });
}
