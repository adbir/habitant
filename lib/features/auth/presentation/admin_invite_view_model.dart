import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/models/address.dart';
import '../../../core/models/housing.dart';
import '../../../core/models/invitation.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

/// The sequential steps of the admin invite creation flow.
enum AdminInviteStep { loading, housingPicker, addressPicker, created }

/// Orchestrates invitation creation for staff.
///
/// Staff select a housing, then an address, and an [Invitation] is created.
/// The resulting deep link URL is displayed for manual sharing.
class AdminInviteViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthService _authService;

  AdminInviteStep _step = AdminInviteStep.loading;
  bool _isLoading = false;
  bool _hasError = false;

  List<Housing> _housings = const [];
  Housing? _selectedHousing;
  Invitation? _createdInvitation;

  AdminInviteViewModel({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  AdminInviteStep get step => _step;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  List<Housing> get housings => _housings;
  Housing? get selectedHousing => _selectedHousing;
  Invitation? get createdInvitation => _createdInvitation;

  /// The full deep link URL for the created invitation.
  String get invitationLink {
    final token = _createdInvitation?.token ?? '';
    return 'https://habitant.app/join?token=$token';
  }

  Future<void> load() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();
    try {
      final staffId = _authService.tenantId ?? '';
      _housings = await _apiClient.getStaffHousings(staffId);
      _step = AdminInviteStep.housingPicker;
    } catch (e, s) {
      developer.log(
        'Failed to load housings for invite screen',
        name: 'AdminInviteViewModel',
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

  void selectHousing(Housing housing) {
    _selectedHousing = housing;
    _step = AdminInviteStep.addressPicker;
    notifyListeners();
  }

  Future<void> selectAddress(Address address) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();
    try {
      _createdInvitation = await _apiClient.createInvitation(address.id);
      _step = AdminInviteStep.created;
    } catch (e, s) {
      developer.log(
        'Failed to create invitation',
        name: 'AdminInviteViewModel',
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

  void goBack() {
    if (_step == AdminInviteStep.addressPicker) {
      _step = AdminInviteStep.housingPicker;
      _selectedHousing = null;
      _hasError = false;
      notifyListeners();
    }
  }

  void reset() {
    _step = AdminInviteStep.housingPicker;
    _selectedHousing = null;
    _createdInvitation = null;
    _hasError = false;
    notifyListeners();
  }
}
