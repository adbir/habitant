import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/models/address.dart';
import '../../../core/models/housing.dart';
import '../../../core/models/issue.dart';
import '../../../core/models/tenant_profile.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

/// Loads and holds the data for the tenant home screen.
///
/// After the profile loads, address, housing name, and issues are all fetched
/// in parallel to minimise wait time.
class TenantHomeViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthService _authService;

  bool _isLoading = true;
  bool _hasError = false;
  TenantProfile? _profile;
  Housing? _housing;
  Address? _address;
  List<Issue> _issues = const [];

  TenantHomeViewModel({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  TenantProfile? get profile => _profile;
  Housing? get housing => _housing;
  Address? get address => _address;
  List<Issue> get issues => _issues;

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
        final housingId = profile.currentHousingId!;
        final addressId = profile.currentAddressId!;

        final results = await Future.wait([
          _apiClient.getHousing(housingId),
          _apiClient.getAddress(housingId, addressId),
          _apiClient.getTenantIssues(tenantId, addressId),
        ]);

        _housing = results[0] as Housing;
        _address = results[1] as Address;
        _issues = (results[2] as List).cast<Issue>();
      }
    } catch (e, s) {
      developer.log(
        'Failed to load tenant home',
        name: 'TenantHomeViewModel',
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

  Future<void> refresh() => load();
}
