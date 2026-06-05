import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/models/housing.dart';
import '../../../core/models/issue.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

/// Filter applied to the maintenance issue list.
enum IssueStatusFilter {
  all,
  pending,
  assigned,
  inProgress,
  completed,
  rejected,
}

/// Drives the maintenance worker dashboard.
class MaintenanceDashboardViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthService _authService;

  bool _isLoading = false;
  bool _hasError = false;
  final List<Issue> _issues = [];
  final List<Housing> _housings = [];
  IssueStatusFilter _filter = IssueStatusFilter.all;

  MaintenanceDashboardViewModel({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  IssueStatusFilter get filter => _filter;

  List<Issue> get filteredIssues {
    if (_filter == IssueStatusFilter.all) {
      return List.unmodifiable(_issues);
    }
    final target = _issueStatusFor(_filter);
    return _issues.where((i) => i.status == target).toList();
  }

  IssueStatus _issueStatusFor(IssueStatusFilter f) => switch (f) {
        IssueStatusFilter.pending => IssueStatus.pending,
        IssueStatusFilter.assigned => IssueStatus.assigned,
        IssueStatusFilter.inProgress => IssueStatus.inProgress,
        IssueStatusFilter.completed => IssueStatus.completed,
        IssueStatusFilter.rejected => IssueStatus.rejected,
        IssueStatusFilter.all => IssueStatus.pending,
      };

  /// Short address string for [issue], resolved from cached housing data.
  String addressDisplayFor(Issue issue) {
    for (final housing in _housings) {
      for (final address in housing.addresses) {
        if (address.id == issue.addressId) {
          return address.shortDisplayAddress;
        }
      }
    }
    return '';
  }

  /// Housing name for [issue], resolved from cached housing data.
  String housingNameFor(Issue issue) {
    for (final housing in _housings) {
      if (housing.id == issue.housingId) return housing.name;
    }
    return '';
  }

  /// Number of issues matching [filter].
  int countFor(IssueStatusFilter filter) {
    if (filter == IssueStatusFilter.all) return _issues.length;
    final status = _issueStatusFor(filter);
    return _issues.where((i) => i.status == status).length;
  }

  void setFilter(IssueStatusFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> load() async {
    final staffId = _authService.tenantId;
    if (staffId == null) return;

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final housings = await _apiClient.getStaffHousings(staffId);
      _housings
        ..clear()
        ..addAll(housings);

      final issueResults = await Future.wait(
        housings.map((h) => _apiClient.getHousingIssues(h.id)),
      );
      _issues
        ..clear()
        ..addAll(issueResults.expand((result) => result.items))
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on ApiException catch (_) {
      _hasError = true;
    } catch (e, s) {
      developer.log(
        'Failed to load maintenance dashboard',
        name: 'MaintenanceDashboardViewModel',
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
