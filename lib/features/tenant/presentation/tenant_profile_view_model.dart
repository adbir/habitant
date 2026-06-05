import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/models/address.dart';
import '../../../core/models/housing.dart';
import '../../../core/models/tenant_profile.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

class TenantProfileViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthService _authService;

  bool _isLoading = true;
  bool _hasError = false;
  TenantProfile? _profile;
  Housing? _housing;
  Address? _address;

  TenantProfileViewModel({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  TenantProfile? get profile => _profile;
  Housing? get housing => _housing;
  Address? get address => _address;

  Future<void> load() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final tenantId = _authService.tenantId;
      if (tenantId == null) throw StateError('No tenant ID in token');

      final profile = await _apiClient.getTenantProfile(tenantId);
      _profile = profile;

      if (profile.isOnboarded) {
        final results = await Future.wait([
          _apiClient.getHousing(profile.currentHousingId!),
          _apiClient.getAddress(
            profile.currentHousingId!,
            profile.currentAddressId!,
          ),
        ]);
        _housing = results[0] as Housing;
        _address = results[1] as Address;
      }
    } catch (e, s) {
      developer.log(
        'Failed to load tenant profile',
        name: 'TenantProfileViewModel',
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
}
