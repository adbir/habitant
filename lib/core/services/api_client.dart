import 'dart:typed_data';

import '../models/address.dart';
import '../models/housing.dart';
import '../models/invitation.dart';
import '../models/issue.dart';
import '../models/paged_result.dart';
import '../models/tenant_profile.dart';

class ApiClient {
  String? authToken;

  ApiClient({this.authToken});

  // Auth

  Future<String> login(String email, String password) => throw UnimplementedError();

  Future<void> signup(String email, String password, {String? phoneNumber}) =>
      throw UnimplementedError();

  Future<void> resendVerificationCode(String email) => throw UnimplementedError();

  Future<String> verifyEmail(String email, String code) => throw UnimplementedError();

  // Housing

  Future<Housing> getHousing(String housingId) => throw UnimplementedError();

  Future<Address> getAddress(String housingId, String addressId) =>
      throw UnimplementedError();

  // Tenant

  Future<TenantProfile> getTenantProfile(String tenantId) => throw UnimplementedError();

  Future<List<Issue>> getTenantIssues(String tenantId, String addressId) =>
      throw UnimplementedError();

  /// All issues ever reported by [tenantId], across every address they have lived at.
  Future<List<Issue>> getTenantAllIssues(String tenantId) => throw UnimplementedError();

  Future<String> uploadIssuePhoto(Uint8List bytes, String filename) =>
      throw UnimplementedError();

  Future<Issue> reportIssue(
    String tenantId,
    String addressId,
    String description,
    List<String> photoUrls, {
    String? alternativeContactPhone,
  }) => throw UnimplementedError();

  Future<void> moveTenantToAddress(String tenantId, String newAddressId) =>
      throw UnimplementedError();

  // Staff

  Future<List<Housing>> getStaffHousings(String staffId) => throw UnimplementedError();

  Future<PagedResult<Issue>> getHousingIssues(
    String housingId, {
    Set<IssueStatus>? statuses,
    int page = 0,
    int pageSize = 25,
  }) => throw UnimplementedError();

  Future<Issue> getIssue(String issueId) => throw UnimplementedError();

  Future<Issue> addIssueComment(String issueId, String body, bool isPrivate) =>
      throw UnimplementedError();

  Future<Issue> addMaintenanceUpdate(
    String issueId,
    String description,
    List<String> proofPhotoUrls,
  ) => throw UnimplementedError();

  // Invitations

  Future<Invitation> getInvitationByToken(String token) => throw UnimplementedError();

  Future<Invitation> createInvitation(String addressId) => throw UnimplementedError();

  Future<void> cancelInvitation(String invitationId) => throw UnimplementedError();

  Future<List<Invitation>> getHousingInvitations(String housingId) =>
      throw UnimplementedError();

  Future<void> claimInvitation({
    required String userId,
    required String email,
    required String housingId,
    required String addressId,
    String? phoneNumber,
  }) => throw UnimplementedError();

  Future<List<TenantProfile>> getAddressTenants(String addressId) =>
      throw UnimplementedError();

  // Admin

  Future<Issue> markNeedsAssistance(String issueId) => throw UnimplementedError();

  Future<TenantProfile> markTenantMovedOut(String tenantId, String addressId) =>
      throw UnimplementedError();
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException: $statusCode - $message';
}

/// Thrown when an invitation token is not found, expired, or cancelled.
class InvitationNotFoundException implements Exception {
  const InvitationNotFoundException();
}
