import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/address.dart';
import '../models/housing.dart';
import '../models/invitation.dart';
import '../models/issue.dart';
import '../models/tenant_profile.dart';

class ApiClient {
  final String baseUrl;
  String? authToken;

  ApiClient({
    required this.baseUrl,
    this.authToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<T> _get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return fromJson(json);
      }

      throw ApiException(response.statusCode, response.body);
    } catch (e, s) {
      developer.log(
        'GET $endpoint failed',
        error: e,
        stackTrace: s,
        name: 'ApiClient',
      );
      rethrow;
    }
  }

  Future<List<T>> _getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw ApiException(response.statusCode, response.body);
    } catch (e, s) {
      developer.log(
        'GET $endpoint failed',
        error: e,
        stackTrace: s,
        name: 'ApiClient',
      );
      rethrow;
    }
  }

  Future<T> _post<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return fromJson(json);
      }

      throw ApiException(response.statusCode, response.body);
    } catch (e, s) {
      developer.log(
        'POST $endpoint failed',
        error: e,
        stackTrace: s,
        name: 'ApiClient',
      );
      rethrow;
    }
  }

  Future<T> _patch<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return fromJson(json);
      }

      throw ApiException(response.statusCode, response.body);
    } catch (e, s) {
      developer.log(
        'PATCH $endpoint failed',
        error: e,
        stackTrace: s,
        name: 'ApiClient',
      );
      rethrow;
    }
  }

  /// Auth endpoints

  Future<String> login(String email, String password) async {
    final result = await _post(
      '/auth/login',
      {'email': email, 'password': password},
      (json) => json['token'] as String,
    );
    return result;
  }

  /// Initiates signup by sending a verification code to [email].
  Future<void> signup(
    String email,
    String password, {
    String? phoneNumber,
  }) async {
    await _post(
      '/auth/signup',
      {
        'email': email,
        'password': password,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phoneNumber': phoneNumber,
      },
      (_) => null,
    );
  }

  /// Resends the verification code to [email].
  Future<void> resendVerificationCode(String email) async {
    await _post(
      '/auth/resend-code',
      {'email': email},
      (_) => null,
    );
  }

  /// Verifies the OTP [code] for [email] and returns a JWT on success.
  Future<String> verifyEmail(String email, String code) async {
    final result = await _post(
      '/auth/verify-email',
      {'email': email, 'code': code},
      (json) => json['token'] as String,
    );
    return result;
  }

  /// Returns all housings available for tenant signup.
  Future<List<Housing>> getHousings() async {
    return _getList('/housings', Housing.fromJson);
  }

  /// Returns a single housing by ID.
  Future<Housing> getHousing(String housingId) async {
    return _get('/housings/$housingId', Housing.fromJson);
  }

  /// Returns a single address by its housing and address IDs.
  Future<Address> getAddress(String housingId, String addressId) async {
    return _get(
      '/housings/$housingId/addresses/$addressId',
      Address.fromJson,
    );
  }

  /// Sets the tenant's housing and address after signup.
  Future<void> setTenantHousingAddress(
    String tenantId,
    String housingId,
    String addressId,
  ) async {
    await _patch(
      '/tenants/$tenantId/housing-address',
      {'housingId': housingId, 'addressId': addressId},
      (_) => null,
    );
  }

  /// Tenant endpoints
  Future<TenantProfile> getTenantProfile(String tenantId) async {
    return _get(
      '/tenants/$tenantId',
      TenantProfile.fromJson,
    );
  }

  Future<List<Issue>> getTenantIssues(
    String tenantId,
    String addressId,
  ) async {
    return _getList(
      '/tenants/$tenantId/addresses/$addressId/issues',
      Issue.fromJson,
    );
  }

  /// Uploads a photo and returns its permanent URL.
  Future<String> uploadIssuePhoto(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/uploads/issue-photo');
      final request = http.MultipartRequest('POST', uri);
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.files.add(
        http.MultipartFile.fromBytes('photo', bytes, filename: filename),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['url'] as String;
      }
      throw ApiException(response.statusCode, response.body);
    } catch (e, s) {
      developer.log(
        'POST /uploads/issue-photo failed',
        error: e,
        stackTrace: s,
        name: 'ApiClient',
      );
      rethrow;
    }
  }

  Future<Issue> reportIssue(
    String tenantId,
    String addressId,
    String description,
    List<String> photoUrls, {
    String? alternativeContactPhone,
  }) async {
    return _post(
      '/tenants/$tenantId/issues',
      {
        'addressId': addressId,
        'description': description,
        'photoUrls': photoUrls,
        'alternativeContactPhone': ?alternativeContactPhone,
      },
      Issue.fromJson,
    );
  }

  Future<void> moveTenantToAddress(
    String tenantId,
    String newAddressId,
  ) async {
    await _patch(
      '/tenants/$tenantId/move-address',
      {'newAddressId': newAddressId},
      (json) => null,
    );
  }

  /// Housing/Staff endpoints
  Future<List<Housing>> getStaffHousings(String staffId) async {
    return _getList(
      '/staff/$staffId/housings',
      Housing.fromJson,
    );
  }

  Future<List<Issue>> getHousingIssues(String housingId) async {
    return _getList(
      '/housing/$housingId/issues',
      Issue.fromJson,
    );
  }

  /// Returns a single issue by ID.
  Future<Issue> getIssue(String issueId) async {
    return _get('/issues/$issueId', Issue.fromJson);
  }

  /// Adds a comment to an issue and returns the updated issue.
  ///
  /// [isPrivate] true limits visibility to staff; false also shows
  /// the comment to the tenant.
  Future<Issue> addIssueComment(
    String issueId,
    String body,
    bool isPrivate,
  ) async {
    return _post(
      '/issues/$issueId/comments',
      {'body': body, 'isPrivate': isPrivate},
      Issue.fromJson,
    );
  }

  /// Maintenance endpoints
  Future<Issue> addMaintenanceUpdate(
    String issueId,
    String description,
    List<String> proofPhotoUrls,
  ) async {
    return _post(
      '/issues/$issueId/maintenance-updates',
      {
        'description': description,
        'proofPhotoUrls': proofPhotoUrls,
      },
      Issue.fromJson,
    );
  }

  /// Invitation endpoints

  /// Returns an active [Invitation] by its [token], including the pre-assigned
  /// address and housing name. Throws [InvitationNotFoundException] if the
  /// token is invalid or expired.
  Future<Invitation> getInvitationByToken(String token) async {
    throw UnimplementedError();
  }

  /// Creates an invitation for [addressId] and returns it with address details.
  Future<Invitation> createInvitation(String addressId) async {
    throw UnimplementedError();
  }

  /// Cancels an invitation by setting its [cancelled_at] timestamp.
  Future<void> cancelInvitation(String invitationId) async {
    throw UnimplementedError();
  }

  /// Admin endpoints
  Future<Issue> markNeedsAssistance(String issueId) async {
    return _patch(
      '/issues/$issueId',
      {'needAssistance': true},
      Issue.fromJson,
    );
  }

  Future<TenantProfile> markTenantMovedOut(
    String tenantId,
    String addressId,
  ) async {
    return _patch(
      '/tenants/$tenantId/addresses/$addressId/mark-moved-out',
      {},
      TenantProfile.fromJson,
    );
  }
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
