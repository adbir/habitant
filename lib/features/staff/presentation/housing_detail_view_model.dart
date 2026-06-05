import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/models/address.dart';
import '../../../core/models/housing.dart';
import '../../../core/models/invitation.dart';
<<<<<<< HEAD
import '../../../core/models/issue.dart';
=======
>>>>>>> administration-overview
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

/// Status of a single address from the admin's perspective.
enum AddressStatus { occupied, invitationPending, vacant }

/// Drives the housing detail screen for admins.
///
<<<<<<< HEAD
/// Shows all addresses with their occupancy/invitation status, pending
/// invitations (with cancel support), and open issues for the housing.
=======
/// Manages addresses, their occupancy status, and invitation actions.
/// Issues are handled separately by [HousingIssuesViewModel].
>>>>>>> administration-overview
class HousingDetailViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  final Housing _housing;
  List<Invitation> _invitations = const [];
<<<<<<< HEAD
  List<Issue> _openIssues = const [];
=======
>>>>>>> administration-overview
  bool _isLoading = false;
  bool _hasError = false;

  String? _cancellingInvitationId;
  String? _creatingInvitationForAddressId;
  Invitation? _createdInvitation;

  HousingDetailViewModel({
    required ApiClient apiClient,
    required AuthService authService,
    required Housing initialHousing,
  })  : _apiClient = apiClient,
        _housing = initialHousing;

  Housing get housing => _housing;
  List<Invitation> get invitations => List.unmodifiable(_invitations);
<<<<<<< HEAD
  List<Issue> get openIssues => List.unmodifiable(_openIssues);
=======
>>>>>>> administration-overview
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  /// Non-null immediately after a successful invitation creation.
  ///
  /// The screen shows a bottom sheet with the link, then calls
  /// [clearCreatedInvitation] on dismiss.
  Invitation? get createdInvitation => _createdInvitation;

  bool isCancelling(String invitationId) =>
      _cancellingInvitationId == invitationId;

  bool isCreating(String addressId) =>
      _creatingInvitationForAddressId == addressId;

  /// The shareable deep-link URL for [invitation].
  String invitationLink(Invitation invitation) =>
      'https://adbir.github.io/habitant/#/join?token=${invitation.token}';

  /// Derives the display status for [address] from the current invitation list.
  AddressStatus statusFor(Address address) {
    if (address.isOccupied) return AddressStatus.occupied;
    final hasPending =
        _invitations.any((inv) => inv.addressId == address.id);
    return hasPending
        ? AddressStatus.invitationPending
        : AddressStatus.vacant;
  }

  Future<void> load() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();
    try {
<<<<<<< HEAD
      final results = await Future.wait([
        _apiClient.getHousingInvitations(_housing.id),
        _apiClient.getHousingIssues(_housing.id),
      ]);
      _invitations = results[0] as List<Invitation>;
      _openIssues = (results[1] as List<Issue>)
          .where(
            (i) =>
                i.status != IssueStatus.completed &&
                i.status != IssueStatus.rejected,
          )
          .toList();
=======
      _invitations = await _apiClient.getHousingInvitations(_housing.id);
>>>>>>> administration-overview
    } catch (e, s) {
      developer.log(
        'Failed to load housing detail',
        name: 'HousingDetailViewModel',
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

  Future<void> createInvitation(String addressId) async {
    _creatingInvitationForAddressId = addressId;
    _hasError = false;
    notifyListeners();
    try {
      final inv = await _apiClient.createInvitation(addressId);
      _invitations = [..._invitations, inv];
      _createdInvitation = inv;
    } catch (e, s) {
      developer.log(
        'Failed to create invitation',
        name: 'HousingDetailViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _hasError = true;
    } finally {
      _creatingInvitationForAddressId = null;
      notifyListeners();
    }
  }

  Future<void> cancelInvitation(String invitationId) async {
    _cancellingInvitationId = invitationId;
    notifyListeners();
    try {
      await _apiClient.cancelInvitation(invitationId);
      _invitations =
          _invitations.where((inv) => inv.id != invitationId).toList();
    } catch (e, s) {
      developer.log(
        'Failed to cancel invitation',
        name: 'HousingDetailViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
    } finally {
      _cancellingInvitationId = null;
      notifyListeners();
    }
  }

  void clearCreatedInvitation() {
    _createdInvitation = null;
    notifyListeners();
  }

  Future<void> refresh() => load();
}
