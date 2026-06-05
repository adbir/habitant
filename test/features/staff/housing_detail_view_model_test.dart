import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:beboer_app/core/models/address.dart';
import 'package:beboer_app/core/models/housing.dart';
import 'package:beboer_app/core/models/invitation.dart';
import 'package:beboer_app/core/services/api_client.dart';
import 'package:beboer_app/core/services/auth_service.dart';
import 'package:beboer_app/features/staff/presentation/housing_detail_view_model.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

class MockAuthService extends Mock implements AuthService {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Address _address({
  required String id,
  required String housingId,
  bool occupied = false,
}) =>
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
      name: 'Test Housing',
      city: 'København',
      addresses: addresses,
      createdAt: DateTime(2024),
    );

Invitation _invitation({required String id, required String addressId}) =>
    Invitation(
      id: id,
      token: 'token-$id',
      addressId: addressId,
      expiresAt: DateTime(2030),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient api;
  late MockAuthService auth;

  final addr1 = _address(id: 'a1', housingId: 'h1', occupied: true);
  final addr2 = _address(id: 'a2', housingId: 'h1');
  final addr3 = _address(id: 'a3', housingId: 'h1');
  final housing = _housing('h1', [addr1, addr2, addr3]);

  setUp(() {
    api = MockApiClient();
    auth = MockAuthService();
    when(() => api.getHousingInvitations(any()))
        .thenAnswer((_) async => const []);
  });

  HousingDetailViewModel makeVm() => HousingDetailViewModel(
        apiClient: api,
        authService: auth,
        initialHousing: housing,
      );

  // -------------------------------------------------------------------------
  // load()
  // -------------------------------------------------------------------------

  group('load()', () {
    test('success: invitations populated', () async {
      final inv = _invitation(id: 'inv1', addressId: 'a2');
      when(() => api.getHousingInvitations('h1'))
          .thenAnswer((_) async => [inv]);

      final vm = makeVm();
      await vm.load();

      check(vm.invitations).length.equals(1);
      check(vm.hasError).isFalse();
      check(vm.isLoading).isFalse();
    });

    test('API error: hasError is true', () async {
      when(() => api.getHousingInvitations(any()))
          .thenThrow(Exception('network error'));

      final vm = makeVm();
      await vm.load();

      check(vm.hasError).isTrue();
      check(vm.isLoading).isFalse();
    });
  });

  // -------------------------------------------------------------------------
  // statusFor()
  // -------------------------------------------------------------------------

  group('statusFor()', () {
    late HousingDetailViewModel vm;

    setUp(() async {
      final inv = _invitation(id: 'inv1', addressId: 'a2');
      when(() => api.getHousingInvitations('h1'))
          .thenAnswer((_) async => [inv]);
      vm = makeVm();
      await vm.load();
    });

    test('occupied address → AddressStatus.occupied', () {
      check(vm.statusFor(addr1)).equals(AddressStatus.occupied);
    });

    test('vacant address with matching invitation → invitationPending', () {
      check(vm.statusFor(addr2)).equals(AddressStatus.invitationPending);
    });

    test('vacant address with no invitation → vacant', () {
      check(vm.statusFor(addr3)).equals(AddressStatus.vacant);
    });
  });

  // -------------------------------------------------------------------------
  // cancelInvitation()
  // -------------------------------------------------------------------------

  group('cancelInvitation()', () {
    test('success: invitation removed from list', () async {
      final inv = _invitation(id: 'inv1', addressId: 'a2');
      when(() => api.getHousingInvitations('h1'))
          .thenAnswer((_) async => [inv]);
      when(() => api.cancelInvitation('inv1')).thenAnswer((_) async {});

      final vm = makeVm();
      await vm.load();
      check(vm.invitations).length.equals(1);

      await vm.cancelInvitation('inv1');

      check(vm.invitations).isEmpty();
      check(vm.isCancelling('inv1')).isFalse();
    });

    test('isCancelling is true while in-flight', () async {
      final inv = _invitation(id: 'inv1', addressId: 'a2');
      when(() => api.getHousingInvitations('h1'))
          .thenAnswer((_) async => [inv]);

      final completer = Completer<void>();
      when(() => api.cancelInvitation(any()))
          .thenAnswer((_) async => completer.future);

      final vm = makeVm();
      await vm.load();

      final cancelFuture = vm.cancelInvitation('inv1');
      check(vm.isCancelling('inv1')).isTrue();
      completer.complete();
      await cancelFuture;
      check(vm.isCancelling('inv1')).isFalse();
    });

    test('API error: invitation stays in list', () async {
      final inv = _invitation(id: 'inv1', addressId: 'a2');
      when(() => api.getHousingInvitations('h1'))
          .thenAnswer((_) async => [inv]);
      when(() => api.cancelInvitation('inv1'))
          .thenThrow(Exception('network error'));

      final vm = makeVm();
      await vm.load();
      await vm.cancelInvitation('inv1');

      check(vm.invitations).length.equals(1);
      check(vm.isCancelling('inv1')).isFalse();
    });
  });

  // -------------------------------------------------------------------------
  // createInvitation()
  // -------------------------------------------------------------------------

  group('createInvitation()', () {
    test('success: invitation added and createdInvitation set', () async {
      final newInv = _invitation(id: 'inv-new', addressId: 'a3');
      when(() => api.createInvitation('a3'))
          .thenAnswer((_) async => newInv);

      final vm = makeVm();
      await vm.load();
      await vm.createInvitation('a3');

      check(vm.invitations).length.equals(1);
      check(vm.createdInvitation).equals(newInv);
      check(vm.isCreating('a3')).isFalse();
    });

    test('isCreating is true while in-flight', () async {
      final completer = Completer<Invitation>();
      when(() => api.createInvitation(any()))
          .thenAnswer((_) async => completer.future);

      final vm = makeVm();
      await vm.load();

      final createFuture = vm.createInvitation('a3');
      check(vm.isCreating('a3')).isTrue();
      completer.complete(_invitation(id: 'inv-new', addressId: 'a3'));
      await createFuture;
      check(vm.isCreating('a3')).isFalse();
    });

    test('clearCreatedInvitation resets to null', () async {
      when(() => api.createInvitation('a3'))
          .thenAnswer((_) async => _invitation(id: 'inv-new', addressId: 'a3'));

      final vm = makeVm();
      await vm.load();
      await vm.createInvitation('a3');
      check(vm.createdInvitation).isNotNull();

      vm.clearCreatedInvitation();
      check(vm.createdInvitation).isNull();
    });
  });
}
