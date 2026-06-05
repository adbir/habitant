import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/address.dart';
import '../models/housing.dart';
import '../models/invitation.dart';
import '../models/issue.dart';
import '../models/issue_comment.dart';
import '../models/maintenance_update.dart';
import '../models/paged_result.dart';
import '../models/tenant_profile.dart';
import 'api_client.dart';

/// Production [ApiClient] backed by Supabase.
///
/// Auth operations (login, signup, OTP) are handled by [AuthService] and
/// Supabase Auth — the corresponding base-class methods are unused here.
/// All data queries use the Supabase PostgREST client; row-level security
/// on the database enforces access control automatically.
class SupabaseApiClient extends ApiClient {
  SupabaseApiClient() : super(baseUrl: '');

  static SupabaseClient get _client => Supabase.instance.client;

  /// Full nested select used for every issue fetch.
  static const _issueSelect = '''
    *,
    address!inner(housing_id),
    staff_user!maintenance_staff_id(first_name),
    issue_photo(url),
    issue_comment(
      issue_comment_id, body, created, author_id,
      issue_comment_flags,
      staff_user!author_id(name)
    ),
    maintenance_update(
      maintenance_update_id, description, completed_at,
      maintenance_staff_id,
      maintenance_update_photo(url)
    )
  ''';

  // ---- Housing ---------------------------------------------------------------

  @override
  Future<Housing> getHousing(String housingId) async {
    final row = await _client
        .from('housing')
        .select('*, address(*)')
        .eq('housing_id', housingId)
        .single();
    return _housingFromRow(row);
  }

  @override
  Future<Address> getAddress(String housingId, String addressId) async {
    final row = await _client
        .from('address')
        .select()
        .eq('address_id', addressId)
        .eq('housing_id', housingId)
        .single();
    return _addressFromRow(row);
  }

  // ---- Tenant ----------------------------------------------------------------

  @override
  Future<TenantProfile> getTenantProfile(String tenantId) async {
    final row = await _client
        .from('tenant')
        .select()
        .eq('tenant_id', tenantId)
        .single();
    return _tenantFromRow(row);
  }

  @override
  Future<List<Issue>> getTenantIssues(
    String tenantId,
    String addressId,
  ) async {
    final rows = await _client
        .from('issue')
        .select(_issueSelect)
        .eq('tenant_id', tenantId)
        .eq('address_id', addressId)
        .order('created', ascending: false);
    return rows.map(_issueFromRow).toList();
  }

  @override
  Future<String> uploadIssuePhoto(Uint8List bytes, String filename) async {
    final path = '${_client.auth.currentUser!.id}/$filename';
    await _client.storage.from('issue-photos').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    return _client.storage.from('issue-photos').getPublicUrl(path);
  }

  @override
  Future<Issue> reportIssue(
    String tenantId,
    String addressId,
    String description,
    List<String> photoUrls, {
    String? alternativeContactPhone,
  }) async {
    final issueRow = await _client.from('issue').insert({
      'tenant_id': tenantId,
      'address_id': addressId,
      'description': description,
      // ignore: use_null_aware_elements
      if (alternativeContactPhone != null)
        'alternative_contact_phone': alternativeContactPhone,
    }).select('issue_id').single();

    final issueId = issueRow['issue_id'] as String;

    if (photoUrls.isNotEmpty) {
      await _client.from('issue_photo').insert(
        photoUrls.map((url) => {'issue_id': issueId, 'url': url}).toList(),
      );
    }

    return getIssue(issueId);
  }

  @override
  Future<void> moveTenantToAddress(
    String tenantId,
    String newAddressId,
  ) async {
    await _client.from('tenant').update({
      'current_address_id': newAddressId,
    }).eq('tenant_id', tenantId);
  }

  // ---- Staff -----------------------------------------------------------------

  @override
  Future<List<Housing>> getStaffHousings(String staffId) async {
    // RLS on staff_housing_access already scopes rows to the calling user.
    final accessRows = await _client
        .from('staff_housing_access')
        .select('housing_id');

    if (accessRows.isEmpty) return [];

    final housingIds =
        accessRows.map((r) => r['housing_id'] as String).toList();

    final rows = await _client
        .from('housing')
        .select('*, address(*)')
        .inFilter('housing_id', housingIds)
        .order('name');

    return rows.map(_housingFromRow).toList();
  }

  @override
  Future<PagedResult<Issue>> getHousingIssues(
    String housingId, {
    Set<IssueStatus>? statuses,
    int page = 0,
    int pageSize = 25,
  }) async {
    var query = _client
        .from('issue')
        .select(_issueSelect)
        .eq('address.housing_id', housingId);

    if (statuses != null) {
      query = query.inFilter(
        'status',
        statuses.map((s) => s.name).toList(),
      );
    }

    final rows = await query
        .order('created', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize);

    final items = rows.map(_issueFromRow).toList();
    return PagedResult(
      items: items,
      hasMore: items.length == pageSize,
    );
  }

  @override
  Future<Issue> getIssue(String issueId) async {
    final row = await _client
        .from('issue')
        .select(_issueSelect)
        .eq('issue_id', issueId)
        .single();
    return _issueFromRow(row);
  }

  @override
  Future<Issue> addIssueComment(
    String issueId,
    String body,
    bool isPrivate,
  ) async {
    await _client.from('issue_comment').insert({
      'issue_id': issueId,
      'body': body,
      'author_id': _client.auth.currentUser!.id,
      'issue_comment_flags': isPrivate ? 1 : 0,
    });
    return getIssue(issueId);
  }

  @override
  Future<Issue> addMaintenanceUpdate(
    String issueId,
    String description,
    List<String> proofPhotoUrls,
  ) async {
    final staffId = _client.auth.currentUser!.id;

    final updateRow = await _client.from('maintenance_update').insert({
      'issue_id': issueId,
      'description': description,
      'maintenance_staff_id': staffId,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    }).select('maintenance_update_id').single();

    final updateId = updateRow['maintenance_update_id'] as String;

    if (proofPhotoUrls.isNotEmpty) {
      await _client.from('maintenance_update_photo').insert(
        proofPhotoUrls
            .map((url) => {'maintenance_update_id': updateId, 'url': url})
            .toList(),
      );
    }

    await _client.from('issue').update({
      'status': 'in_progress',
      'maintenance_staff_id': staffId,
    }).eq('issue_id', issueId);

    return getIssue(issueId);
  }

  // ---- Invitations -----------------------------------------------------------

  @override
  Future<Invitation> getInvitationByToken(String token) async {
    final row = await _client
        .from('tenant_invitation')
        .select('*, address(*, housing:housing_id(name))')
        .eq('token', token)
        .maybeSingle();
    if (row == null) throw const InvitationNotFoundException();
    return Invitation.fromRow(row);
  }

  @override
  Future<Invitation> createInvitation(String addressId) async {
    final staffId = _client.auth.currentUser!.id;
    final row = await _client.from('tenant_invitation').insert({
      'address_id': addressId,
      'created_by': staffId,
    }).select('*, address(*, housing:housing_id(name))').single();
    return Invitation.fromRow(row);
  }

  @override
  Future<void> cancelInvitation(String invitationId) async {
    await _client.from('tenant_invitation').update({
      'cancelled_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('invitation_id', invitationId);
  }

  @override
  Future<List<Invitation>> getHousingInvitations(String housingId) async {
    // RLS policy invitation_select_active already filters expired/cancelled rows.
    // The !inner join restricts results to invitations whose address belongs to
    // the given housing.
    final rows = await _client
        .from('tenant_invitation')
        .select('*, address!inner(*, housing:housing_id(name))')
        .eq('address.housing_id', housingId)
        .order('created', ascending: false);
    return rows.map(Invitation.fromRow).toList();
  }

  // ---- Admin -----------------------------------------------------------------

  @override
  Future<Issue> markNeedsAssistance(String issueId) async {
    final current = await _client
        .from('issue')
        .select('issue_flags')
        .eq('issue_id', issueId)
        .single();
    final flags = (current['issue_flags'] as int? ?? 0) | 1;
    await _client
        .from('issue')
        .update({'issue_flags': flags})
        .eq('issue_id', issueId);
    return getIssue(issueId);
  }

  @override
  Future<TenantProfile> markTenantMovedOut(
    String tenantId,
    String addressId,
  ) async {
    await _client.from('tenant').update({
      'current_address_id': null,
      'tenant_flags': 0,
    }).eq('tenant_id', tenantId);
    return getTenantProfile(tenantId);
  }

  // ---- Row mappers -----------------------------------------------------------

  Housing _housingFromRow(Map<String, dynamic> row) => Housing(
        id: row['housing_id'] as String,
        name: row['name'] as String,
        city: row['city'] as String,
        createdAt: DateTime.parse(row['created'] as String),
        addresses: (row['address'] as List<dynamic>? ?? [])
            .map((a) => _addressFromRow(a as Map<String, dynamic>))
            .toList(),
      );

  Address _addressFromRow(Map<String, dynamic> row) {
    final flags = row['address_flags'] as int? ?? 0;
    return Address(
      id: row['address_id'] as String,
      housingId: row['housing_id'] as String,
      street: row['street'] as String,
      number: row['number'] as String,
      floor: row['floor'] as String?,
      side: row['side'] as String?,
      postalCode: row['postal_code'] as String,
      city: row['city'] as String,
      isOccupied: (flags & 1) == 1,
      customerApartmentIdentifier:
          row['customer_apartment_identifier'] as String?,
      history: const [],
    );
  }

  TenantProfile _tenantFromRow(Map<String, dynamic> row) => TenantProfile(
        id: row['tenant_id'] as String,
        email: row['email'] as String,
        name: row['name'] as String?,
        phoneNumber: row['phone_number'] as String?,
        phoneNumberSecondary: row['phone_number_secondary'] as String?,
        currentHousingId: row['current_housing_id'] as String?,
        currentAddressId: row['current_address_id'] as String?,
        customerTenantIdentifier:
            row['customer_tenant_identifier'] as String?,
        createdAt: DateTime.parse(row['created'] as String),
      );

  Issue _issueFromRow(Map<String, dynamic> row) {
    final address = row['address'] as Map<String, dynamic>?;
    final assignedStaff = row['staff_user'] as Map<String, dynamic>?;
    final flags = row['issue_flags'] as int? ?? 0;

    final photos = (row['issue_photo'] as List<dynamic>? ?? [])
        .map((p) => (p as Map<String, dynamic>)['url'] as String)
        .toList();

    final comments = (row['issue_comment'] as List<dynamic>? ?? [])
        .map((c) => _commentFromRow(c as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final updates = (row['maintenance_update'] as List<dynamic>? ?? [])
        .map((u) => _updateFromRow(u as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    return Issue(
      id: row['issue_id'] as String,
      tenantId: row['tenant_id'] as String,
      addressId: row['address_id'] as String,
      housingId: address?['housing_id'] as String? ?? '',
      description: row['description'] as String,
      photoUrls: photos,
      status: _parseIssueStatus(row['status'] as String),
      needAssistance: (flags & 1) == 1,
      alternativeContactPhone: row['alternative_contact_phone'] as String?,
      maintenanceStaffId: row['maintenance_staff_id'] as String?,
      assignedToName: assignedStaff?['first_name'] as String?,
      updates: updates,
      comments: comments,
      createdAt: DateTime.parse(row['created'] as String),
      updatedAt: row['modified'] != null
          ? DateTime.parse(row['modified'] as String)
          : null,
    );
  }

  IssueComment _commentFromRow(Map<String, dynamic> row) {
    final author = row['staff_user'] as Map<String, dynamic>?;
    final flags = row['issue_comment_flags'] as int? ?? 0;
    return IssueComment(
      id: row['issue_comment_id'] as String,
      authorId: row['author_id'] as String,
      authorName: author?['name'] as String?,
      body: row['body'] as String,
      isPrivate: (flags & 1) == 1,
      createdAt: DateTime.parse(row['created'] as String),
    );
  }

  MaintenanceUpdate _updateFromRow(Map<String, dynamic> row) {
    final proofPhotos = (row['maintenance_update_photo'] as List<dynamic>? ?? [])
        .map((p) => (p as Map<String, dynamic>)['url'] as String)
        .toList();
    return MaintenanceUpdate(
      id: row['maintenance_update_id'] as String,
      maintenanceStaffId: row['maintenance_staff_id'] as String,
      description: row['description'] as String,
      proofPhotoUrls: proofPhotos,
      completedAt: DateTime.parse(row['completed_at'] as String),
    );
  }

  IssueStatus _parseIssueStatus(String value) => switch (value) {
        'pending' => IssueStatus.pending,
        'assigned' => IssueStatus.assigned,
        'in_progress' => IssueStatus.inProgress,
        'completed' => IssueStatus.completed,
        'rejected' => IssueStatus.rejected,
        _ => IssueStatus.pending,
      };
}

