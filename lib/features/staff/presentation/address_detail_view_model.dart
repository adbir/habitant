import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/models/address.dart';
import '../../../core/models/invitation.dart';
import '../../../core/models/tenant_profile.dart';
import '../../../core/services/api_client.dart';
import 'housing_detail_view_model.dart';

class AddressDetailViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final Address _address;

  List<TenantProfile> _currentTenants = const [];
  Invitation? _invitation;
  Map<String, TenantProfile> _tenantProfiles = const {};

  bool _isLoading = false;
  bool _hasError = false;
  bool _isCancellingInvitation = false;
  bool _isCreatingInvitation = false;

  AddressDetailViewModel({
    required ApiClient apiClient,
    required Address address,
  })  : _apiClient = apiClient,
        _address = address;

  Address get address => _address;
  List<TenantProfile> get currentTenants => List.unmodifiable(_currentTenants);
  Invitation? get invitation => _invitation;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isCancellingInvitation => _isCancellingInvitation;
  bool get isCreatingInvitation => _isCreatingInvitation;

  AddressStatus get status {
    if (_address.isOccupied) return AddressStatus.occupied;
    if (_invitation != null) return AddressStatus.invitationPending;
    return AddressStatus.vacant;
  }

  String invitationLink(Invitation inv) =>
      'https://adbir.github.io/habitant/#/join?token=${inv.token}';

  TenantProfile? profileFor(String tenantId) => _tenantProfiles[tenantId];

  Future<void> load() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();
    try {
      final (tenants, allInvitations) = await (
        _apiClient.getAddressTenants(_address.id),
        _apiClient.getHousingInvitations(_address.housingId),
      ).wait;

      _currentTenants = tenants;
      _invitation = allInvitations
          .where((inv) => inv.addressId == _address.id)
          .firstOrNull;

      // Load profiles for history entries (best-effort — ignore missing tenants).
      final historicIds = _address.history.map((r) => r.tenantId).toSet();
      final profiles = await Future.wait(
        historicIds.map(
          (id) => _apiClient
              .getTenantProfile(id)
              .then<TenantProfile?>((p) => p)
              .onError<Object>((_, _) => null),
        ),
      );

      _tenantProfiles = {
        for (final t in tenants) t.id: t,
        for (final p in profiles.whereType<TenantProfile>()) p.id: p,
      };
    } catch (e, s) {
      developer.log(
        'Failed to load address detail',
        name: 'AddressDetailViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createInvitation() async {
    _isCreatingInvitation = true;
    _hasError = false;
    notifyListeners();
    try {
      _invitation = await _apiClient.createInvitation(_address.id);
    } catch (e, s) {
      developer.log(
        'Failed to create invitation',
        name: 'AddressDetailViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _hasError = true;
    } finally {
      _isCreatingInvitation = false;
      notifyListeners();
    }
  }

  Future<void> cancelInvitation() async {
    final inv = _invitation;
    if (inv == null) return;
    _isCancellingInvitation = true;
    notifyListeners();
    try {
      await _apiClient.cancelInvitation(inv.id);
      _invitation = null;
    } catch (e, s) {
      developer.log(
        'Failed to cancel invitation',
        name: 'AddressDetailViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
    } finally {
      _isCancellingInvitation = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();
}
