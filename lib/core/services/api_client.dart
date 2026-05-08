import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import '../models/housing.dart';
import '../models/issue.dart';
import '../models/maintenance_update.dart';
import '../models/tenant_address.dart';
import '../models/tenant_profile.dart';

class ApiClient {
  final String baseUrl;
  final String? authToken;

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
  Future<String> tenantSignup(String email, String password, String housingId) async {
    final result = await _post(
      '/auth/tenant/signup',
      {
        'email': email,
        'password': password,
        'housingId': housingId,
      },
      (json) => json['token'] as String,
    );
    return result;
  }

  Future<String> staffLogin(String email, String password) async {
    final result = await _post(
      '/auth/staff/login',
      {'email': email, 'password': password},
      (json) => json['token'] as String,
    );
    return result;
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

  Future<Issue> reportIssue(
    String tenantId,
    String addressId,
    String description,
    List<String> photoUrls,
  ) async {
    return _post(
      '/tenants/$tenantId/issues',
      {
        'addressId': addressId,
        'description': description,
        'photoUrls': photoUrls,
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

  Future<Issue> markIssueTooComplex(String issueId) async {
    return _patch(
      '/issues/$issueId',
      {'tooComplexForMaintenance': true},
      Issue.fromJson,
    );
  }

  /// Admin endpoints
  Future<Issue> markNeedsOutsideHelp(String issueId) async {
    return _patch(
      '/issues/$issueId',
      {'needsOutsideHelp': true},
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
