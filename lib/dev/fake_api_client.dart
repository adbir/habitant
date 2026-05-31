import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../core/models/address.dart';
import '../core/models/housing.dart';
import '../core/models/invitation.dart';
import '../core/models/issue.dart';
import '../core/models/issue_comment.dart';
import '../core/models/maintenance_update.dart';
import '../core/models/tenant_profile.dart';
import '../core/models/user_role.dart';
import '../core/services/api_client.dart';

/// Drop-in replacement for [ApiClient] that serves seeded dummy data.
///
/// Extends [ApiClient] so it is accepted anywhere the real client is used.
/// All methods simulate a ~100 ms network round-trip.
///
/// Dev credentials (password is always "password"):
///   lars@example.com    — tenant, housing + address set
///   maria@example.com   — tenant, housing + address set
///   peter@example.com   — tenant, no housing yet (onboarding test)
///   admin@aab.dk        — admin
///   tech@aab.dk         — maintenanceStaff
class FakeApiClient extends ApiClient {
  FakeApiClient() : super(baseUrl: 'fake://');

  static const _uuid = Uuid();
  static const _networkDelay = Duration(milliseconds: 100);

  final _tenants = List<TenantProfile>.of(_seedTenants);
  final _housings = List<Housing>.of(_seedHousings);
  final _issues = List<Issue>.of(_seedIssues);
  final _invitations = List<Invitation>.of(_seedInvitations);

  Future<void> _wait() => Future.delayed(_networkDelay);

  /// Generates a JWT whose payload [AuthService] can decode for the role claim.
  String _jwt(String userId, UserRole role) {
    final header = base64Url
        .encode(utf8.encode('{"alg":"none","typ":"JWT"}'))
        .replaceAll('=', '');
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({
          'sub': userId,
          'role': role.name,
          'exp': 9999999999,
        })))
        .replaceAll('=', '');
    return '$header.$payload.dev';
  }

  TenantProfile _findTenant(String id) => _tenants.firstWhere(
        (t) => t.id == id,
        orElse: () => throw ApiException(404, 'Tenant not found'),
      );

  Issue _findIssue(String id) => _issues.firstWhere(
        (i) => i.id == id,
        orElse: () => throw ApiException(404, 'Issue not found'),
      );

  void _replaceTenant(TenantProfile updated) {
    final i = _tenants.indexWhere((t) => t.id == updated.id);
    if (i != -1) _tenants[i] = updated;
  }

  void _replaceIssue(Issue updated) {
    final i = _issues.indexWhere((issue) => issue.id == updated.id);
    if (i != -1) _issues[i] = updated;
  }

  // ---- Auth ----------------------------------------------------------------

  // Pending signups: email → (password, code, phoneNumber?).
  // Code is always '12345678' in dev.
  final _pendingSignups = <String, (String, String, String?)>{};

  @override
  Future<String> login(String email, String password) async {
    await _wait();
    final entry = _credentials[email.toLowerCase()];
    if (entry == null || password != 'password') {
      throw ApiException(401, 'Unauthorized');
    }
    return _jwt(entry.$1, entry.$2);
  }

  @override
  Future<void> signup(
    String email,
    String password, {
    String? phoneNumber,
  }) async {
    await _wait();
    final normalized = email.toLowerCase();
    if (_credentials.containsKey(normalized) ||
        _tenants.any((t) => t.email == normalized)) {
      throw ApiException(409, 'Email already registered');
    }
    // In dev the code is always 12345678 — a real backend would send an email.
    _pendingSignups[normalized] = (password, '12345678', phoneNumber);
  }

  @override
  Future<void> resendVerificationCode(String email) async {
    await _wait();
    final normalized = email.toLowerCase();
    final pending = _pendingSignups[normalized];
    if (pending != null) {
      _pendingSignups[normalized] = (pending.$1, '12345678', pending.$3);
    }
  }

  @override
  Future<String> verifyEmail(String email, String code) async {
    await _wait();
    final normalized = email.toLowerCase();
    final pending = _pendingSignups[normalized];
    if (pending == null || pending.$2 != code) {
      throw ApiException(422, 'Invalid code');
    }
    _pendingSignups.remove(normalized);
    final id = _uuid.v4();
    _tenants.add(TenantProfile(
      id: id,
      email: normalized,
      phoneNumber: pending.$3,
      createdAt: DateTime.now(),
    ));
    return _jwt(id, UserRole.tenant);
  }

  @override
  Future<Housing> getHousing(String housingId) async {
    await _wait();
    return _housings.firstWhere(
      (h) => h.id == housingId,
      orElse: () => throw ApiException(404, 'Housing not found'),
    );
  }

  @override
  Future<Address> getAddress(String housingId, String addressId) async {
    await _wait();
    final housing = _housings.firstWhere(
      (h) => h.id == housingId,
      orElse: () => throw ApiException(404, 'Housing not found'),
    );
    return housing.addresses.firstWhere(
      (a) => a.id == addressId,
      orElse: () => throw ApiException(404, 'Address not found'),
    );
  }

  // ---- Tenant --------------------------------------------------------------

  @override
  Future<TenantProfile> getTenantProfile(String tenantId) async {
    await _wait();
    return _findTenant(tenantId);
  }

  @override
  Future<List<Issue>> getTenantIssues(
    String tenantId,
    String addressId,
  ) async {
    await _wait();
    return _issues
        .where((i) => i.tenantId == tenantId && i.addressId == addressId)
        .toList();
  }

  @override
  Future<String> uploadIssuePhoto(Uint8List bytes, String filename) async {
    await _wait();
    // Return a deterministic placeholder so thumbnails look different per photo.
    return 'https://picsum.photos/seed/${_uuid.v4()}/400/300';
  }

  @override
  Future<Issue> reportIssue(
    String tenantId,
    String addressId,
    String description,
    List<String> photoUrls, {
    String? alternativeContactPhone,
  }) async {
    await _wait();
    final tenant = _findTenant(tenantId);
    final issue = Issue(
      id: _uuid.v4(),
      tenantId: tenantId,
      addressId: addressId,
      housingId: tenant.currentHousingId ?? '',
      description: description,
      photoUrls: photoUrls,
      status: IssueStatus.pending,
      needAssistance: false,
      alternativeContactPhone: alternativeContactPhone,
      assignedToName: null,
      updates: [],
      comments: [],
      createdAt: DateTime.now(),
    );
    _issues.add(issue);
    return issue;
  }

  @override
  Future<void> moveTenantToAddress(
    String tenantId,
    String newAddressId,
  ) async {
    await _wait();
    _replaceTenant(
      _findTenant(tenantId).copyWith(currentAddressId: newAddressId),
    );
  }

  // ---- Housing / Staff -----------------------------------------------------

  @override
  Future<List<Housing>> getStaffHousings(String staffId) async {
    await _wait();
    return List.of(_housings);
  }

  @override
  Future<List<Issue>> getHousingIssues(String housingId) async {
    await _wait();
    return _issues.where((i) => i.housingId == housingId).toList();
  }

  // ---- Maintenance ---------------------------------------------------------

  @override
  Future<Issue> getIssue(String issueId) async {
    await _wait();
    return _findIssue(issueId);
  }

  @override
  Future<Issue> addIssueComment(
    String issueId,
    String body,
    bool isPrivate,
  ) async {
    await _wait();
    final issue = _findIssue(issueId);
    final authorId = _currentUserId;
    final comment = IssueComment(
      id: _uuid.v4(),
      authorId: authorId,
      authorName: _staffNames[authorId],
      body: body,
      isPrivate: isPrivate,
      createdAt: DateTime.now(),
    );
    final updated = issue.copyWith(
      comments: [...issue.comments, comment],
      updatedAt: DateTime.now(),
    );
    _replaceIssue(updated);
    return updated;
  }

  String get _currentUserId {
    final token = authToken;
    if (token == null) return 'unknown';
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'unknown';
      final payload = jsonDecode(
        utf8.decode(
          base64Url.decode(base64Url.normalize(parts[1])),
        ),
      ) as Map<String, dynamic>;
      return payload['sub'] as String? ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  static const _staffNames = <String, String>{
    _idStaffTech: 'Tekniker',
    _idStaffAdmin: 'Admin',
  };

  static const _staffFirstNames = <String, String>{
    _idStaffTech: 'Thomas',
    _idStaffAdmin: 'Anna',
  };

  @override
  Future<Issue> addMaintenanceUpdate(
    String issueId,
    String description,
    List<String> proofPhotoUrls,
  ) async {
    await _wait();
    final issue = _findIssue(issueId);
    final update = MaintenanceUpdate(
      id: _uuid.v4(),
      maintenanceStaffId: authToken ?? 'staff-dev',
      description: description,
      proofPhotoUrls: proofPhotoUrls,
      completedAt: DateTime.now(),
    );
    final staffId = _currentUserId;
    final updated = issue.copyWith(
      status: IssueStatus.inProgress,
      maintenanceStaffId: staffId,
      assignedToName: _staffFirstNames[staffId],
      updates: [...issue.updates, update],
      updatedAt: DateTime.now(),
    );
    _replaceIssue(updated);
    return updated;
  }

  // ---- Invitations ---------------------------------------------------------

  static const _fakeInvitationToken =
      'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  @override
  Future<Invitation> getInvitationByToken(String token) async {
    await _wait();
    if (token != _fakeInvitationToken) {
      throw const InvitationNotFoundException();
    }
    return _fakeInvitation();
  }

  @override
  Future<Invitation> createInvitation(String addressId) async {
    await _wait();
    final address = _housings
        .expand((h) => h.addresses)
        .firstWhere(
          (a) => a.id == addressId,
          orElse: () => throw ApiException(404, 'Address not found'),
        );
    final housing = _housings.firstWhere((h) => h.id == address.housingId);
    final inv = Invitation(
      id: _uuid.v4(),
      token: _uuid.v4(),
      addressId: addressId,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      address: address,
      housingName: housing.name,
    );
    _invitations.add(inv);
    return inv;
  }

  @override
  Future<void> cancelInvitation(String invitationId) async {
    await _wait();
    _invitations.removeWhere((inv) => inv.id == invitationId);
  }

  @override
  Future<List<Invitation>> getHousingInvitations(String housingId) async {
    await _wait();
    return _invitations.where((inv) {
      if (inv.isExpired) return false;
      final address = _housings
          .expand((h) => h.addresses)
          .firstWhere((a) => a.id == inv.addressId, orElse: () => throw StateError(''));
      return address.housingId == housingId;
    }).toList();
  }

  Invitation _fakeInvitation() {
    final address = _housings
        .expand((h) => h.addresses)
        .firstWhere((a) => a.id == _idAddrToms157Stv);
    return Invitation(
      id: 'fake-invite-id',
      token: _fakeInvitationToken,
      addressId: _idAddrToms157Stv,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      address: address,
      housingName: 'AAB Nørrebro',
    );
  }

  // ---- Admin ---------------------------------------------------------------

  @override
  Future<Issue> markNeedsAssistance(String issueId) async {
    await _wait();
    final updated = _findIssue(issueId).copyWith(needAssistance: true);
    _replaceIssue(updated);
    return updated;
  }

  @override
  Future<TenantProfile> markTenantMovedOut(
    String tenantId,
    String addressId,
  ) async {
    await _wait();
    final current = _findTenant(tenantId);
    // copyWith cannot set nullable fields to null, so construct directly.
    final updated = TenantProfile(
      id: current.id,
      email: current.email,
      currentHousingId: current.currentHousingId,
      currentAddressId: null,
      createdAt: current.createdAt,
    );
    _replaceTenant(updated);
    return updated;
  }

  // =========================================================================
  // Seed data
  // =========================================================================

  // Credentials: email → (userId, role). Password is always "password".
  static final _credentials = <String, (String, UserRole)>{
    'lars@example.com': (_idLars, UserRole.tenant),
    'maria@example.com': (_idMaria, UserRole.tenant),
    'peter@example.com': (_idPeter, UserRole.tenant),
    'admin@aab.dk': (_idStaffAdmin, UserRole.admin),
    'tech@aab.dk': (_idStaffTech, UserRole.maintenanceStaff),
  };

  // Tenant IDs
  static const _idLars = '550e8400-e29b-41d4-a716-446655440001';
  static const _idMaria = '550e8400-e29b-41d4-a716-446655440002';
  static const _idPeter = '550e8400-e29b-41d4-a716-446655440003';

  // Staff IDs
  static const _idStaffAdmin = '550e8400-e29b-41d4-a716-446655441001';
  static const _idStaffTech = '550e8400-e29b-41d4-a716-446655441002';

  // Housing IDs
  static const _idHousingAab = '6ba7b810-9dad-41d1-80b4-00c04fd430c1';
  static const _idHousingKab = '6ba7b810-9dad-41d1-80b4-00c04fd430c2';

  // Address IDs
  static const _idAddrRente23_1tv = 'a3bb189e-8bf9-4888-9912-ace4e6543001';
  static const _idAddrRente23_1th = 'a3bb189e-8bf9-4888-9912-ace4e6543002';
  static const _idAddrToms157Stv = 'a3bb189e-8bf9-4888-9912-ace4e6543003';
  static const _idAddrToms1572th = 'a3bb189e-8bf9-4888-9912-ace4e6543004';
  static const _idAddrFalk20Stth = 'a3bb189e-8bf9-4888-9912-ace4e6543005';
  static const _idAddrFalk201tv = 'a3bb189e-8bf9-4888-9912-ace4e6543006';

  // Issue IDs
  static const _idIssueRadiator = 'f47ac10b-58cc-4372-a567-0e02b2c3d101';
  static const _idIssueMold = 'f47ac10b-58cc-4372-a567-0e02b2c3d102';
  static const _idIssueWindow = 'f47ac10b-58cc-4372-a567-0e02b2c3d103';
  static const _idIssueHood = 'f47ac10b-58cc-4372-a567-0e02b2c3d104';

  // Comment IDs
  static const _idCommentR1 = 'cc000001-0000-0000-0000-000000000001';
  static const _idCommentR2 = 'cc000001-0000-0000-0000-000000000002';
  static const _idCommentM1 = 'cc000001-0000-0000-0000-000000000003';
  static const _idCommentH1 = 'cc000001-0000-0000-0000-000000000004';

  // Invitation IDs
  static const _idInvite1 = 'inv-00000001-0000-0000-0000-000000000001';

  // Tenants
  static final _seedTenants = <TenantProfile>[
    TenantProfile(
      id: _idLars,
      email: 'lars@example.com',
      currentHousingId: _idHousingAab,
      currentAddressId: _idAddrRente23_1tv,
      createdAt: DateTime(2023, 3, 1),
    ),
    TenantProfile(
      id: _idMaria,
      email: 'maria@example.com',
      currentHousingId: _idHousingAab,
      currentAddressId: _idAddrRente23_1th,
      createdAt: DateTime(2022, 9, 15),
    ),
    // Peter has no housing — used to test the onboarding flow.
    TenantProfile(
      id: _idPeter,
      email: 'peter@example.com',
      createdAt: DateTime(2024, 1, 10),
    ),
  ];

  // Housings
  static final _seedHousings = <Housing>[
    Housing(
      id: _idHousingAab,
      name: 'AAB Nørrebro',
      city: 'København NV',
      createdAt: DateTime(2015, 6, 1),
      addresses: [
        Address(
          id: _idAddrRente23_1tv,
          housingId: _idHousingAab,
          street: 'Rentemestervej',
          number: '23',
          floor: '1',
          side: 'tv',
          postalCode: '2400',
          city: 'København NV',
          isOccupied: true,
          history: [
            TenancyRecord(
              tenantId: _idLars,
              movedInAt: DateTime(2023, 3, 1),
              issueIds: [_idIssueRadiator, _idIssueMold, _idIssueWindow],
            ),
          ],
        ),
        Address(
          id: _idAddrRente23_1th,
          housingId: _idHousingAab,
          street: 'Rentemestervej',
          number: '23',
          floor: '1',
          side: 'th',
          postalCode: '2400',
          city: 'København NV',
          isOccupied: true,
          history: [
            TenancyRecord(
              tenantId: _idMaria,
              movedInAt: DateTime(2022, 9, 15),
              issueIds: [_idIssueHood],
            ),
          ],
        ),
        Address(
          id: _idAddrToms157Stv,
          housingId: _idHousingAab,
          street: 'Tomsgårdsvej',
          number: '157',
          floor: 'st',
          side: 'tv',
          postalCode: '2400',
          city: 'København NV',
          isOccupied: false,
          history: [],
        ),
        Address(
          id: _idAddrToms1572th,
          housingId: _idHousingAab,
          street: 'Tomsgårdsvej',
          number: '157',
          floor: '2',
          side: 'th',
          postalCode: '2400',
          city: 'København NV',
          isOccupied: false,
          history: [],
        ),
      ],
    ),
    Housing(
      id: _idHousingKab,
      name: 'KAB Frederiksberg',
      city: 'Frederiksberg',
      createdAt: DateTime(2018, 2, 14),
      addresses: [
        Address(
          id: _idAddrFalk20Stth,
          housingId: _idHousingKab,
          street: 'Falkoner Allé',
          number: '20',
          floor: 'st',
          side: 'th',
          postalCode: '2000',
          city: 'Frederiksberg',
          isOccupied: false,
          history: [],
        ),
        Address(
          id: _idAddrFalk201tv,
          housingId: _idHousingKab,
          street: 'Falkoner Allé',
          number: '20',
          floor: '1',
          side: 'tv',
          postalCode: '2000',
          city: 'Frederiksberg',
          isOccupied: false,
          history: [],
        ),
      ],
    ),
  ];

  // Issues
  static final _seedIssues = <Issue>[
    Issue(
      id: _idIssueRadiator,
      tenantId: _idLars,
      addressId: _idAddrRente23_1tv,
      housingId: _idHousingAab,
      description:
          'Radiator i soveværelset lækker vand ned langs væggen. '
          'Det har stået på i ca. en uge.',
      photoUrls: [],
      status: IssueStatus.inProgress,
      needAssistance: false,
      maintenanceStaffId: _idStaffTech,
      assignedToName: 'Thomas',
      updates: [
        MaintenanceUpdate(
          id: 'b14a7b8c-d47b-4734-b301-9e1a2f5c1001',
          maintenanceStaffId: _idStaffTech,
          description:
              'Tilsyn udført. Pakning er slidt og skal udskiftes. '
              'Bestiller reservedel.',
          proofPhotoUrls: [],
          completedAt: DateTime(2024, 11, 3),
        ),
      ],
      comments: [
        IssueComment(
          id: _idCommentR1,
          authorId: _idStaffTech,
          authorName: 'Tekniker',
          body: 'Bestilt reservedel – forventes leveret fredag.',
          isPrivate: true,
          createdAt: DateTime(2024, 11, 4),
        ),
        IssueComment(
          id: _idCommentR2,
          authorId: _idStaffTech,
          authorName: 'Tekniker',
          body:
              'Hej Lars! Vi har bestilt en ny pakning og forventer '
              'at komme forbi fredag den 8. november '
              'mellem kl. 10–12.',
          isPrivate: false,
          createdAt: DateTime(2024, 11, 4),
        ),
      ],
      createdAt: DateTime(2024, 11, 1),
      updatedAt: DateTime(2024, 11, 3),
    ),
    Issue(
      id: _idIssueMold,
      tenantId: _idLars,
      addressId: _idAddrRente23_1tv,
      housingId: _idHousingAab,
      description:
          'Kraftig skimmelsvamp i badeværelsets loft og bag toilettet. '
          'Lugter kraftigt.',
      photoUrls: [],
      status: IssueStatus.pending,
      needAssistance: true,
      updates: [],
      comments: [
        IssueComment(
          id: _idCommentM1,
          authorId: _idStaffAdmin,
          authorName: 'Admin',
          body:
              'Dette kræver professionel skimmelbehandling. '
              'Hvem kan vi kontakte?',
          isPrivate: true,
          createdAt: DateTime(2024, 11, 11),
        ),
      ],
      createdAt: DateTime(2024, 11, 10),
    ),
    Issue(
      id: _idIssueWindow,
      tenantId: _idLars,
      addressId: _idAddrRente23_1tv,
      housingId: _idHousingAab,
      description:
          'Håndtag på køkkenvindue er knækket af og kan ikke lukkes ordentligt.',
      photoUrls: [],
      status: IssueStatus.completed,
      needAssistance: false,
      maintenanceStaffId: _idStaffTech,
      assignedToName: 'Thomas',
      updates: [
        MaintenanceUpdate(
          id: 'b14a7b8c-d47b-4734-b301-9e1a2f5c1002',
          maintenanceStaffId: _idStaffTech,
          description:
              'Udskiftet håndtag på alle vinduer i køkkenet med nye '
              'beslagsdele.',
          proofPhotoUrls: [],
          completedAt: DateTime(2024, 10, 22),
        ),
      ],
      comments: [],
      createdAt: DateTime(2024, 10, 18),
      updatedAt: DateTime(2024, 10, 22),
    ),
    Issue(
      id: _idIssueHood,
      tenantId: _idMaria,
      addressId: _idAddrRente23_1th,
      housingId: _idHousingAab,
      description:
          'Emhætten over komfuret er defekt – motoren laver høj støj '
          'og suger ikke ordentligt.',
      photoUrls: [],
      status: IssueStatus.assigned,
      needAssistance: false,
      maintenanceStaffId: _idStaffTech,
      assignedToName: 'Thomas',
      updates: [],
      comments: [
        IssueComment(
          id: _idCommentH1,
          authorId: _idStaffTech,
          authorName: 'Tekniker',
          body: 'Kigger på det mandag. Skal muligvis bestilles ny motor.',
          isPrivate: true,
          createdAt: DateTime(2024, 11, 9),
        ),
      ],
      createdAt: DateTime(2024, 11, 8),
    ),
  ];

  // Invitations — one seed invitation on a vacant AAB address
  static final _seedInvitations = <Invitation>[
    Invitation(
      id: _idInvite1,
      token: _fakeInvitationToken,
      addressId: _idAddrToms157Stv,
      expiresAt: DateTime(2030, 12, 31),
      address: _seedHousings[0].addresses
          .firstWhere((a) => a.id == _idAddrToms157Stv),
      housingName: 'AAB Nørrebro',
    ),
  ];
}
