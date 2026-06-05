import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/models/housing.dart';
import '../../../core/models/issue.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

/// Drives the admin dashboard — a housing-centric overview for admins and
/// housing managers.
///
/// Loads all accessible housings with their addresses and computes per-housing
/// open issue counts. "Open" means any status that is not completed or
/// rejected.
class AdminDashboardViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthService _authService;

  bool _isLoading = false;
  bool _hasError = false;
  List<Housing> _housings = const [];
  Map<String, int> _openIssueCounts = const {};

  AdminDashboardViewModel({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  List<Housing> get housings => List.unmodifiable(_housings);

  int get totalAddresses =>
      _housings.fold(0, (sum, h) => sum + h.addresses.length);

  int get totalOccupied =>
      _housings.fold(
        0,
        (sum, h) => sum + h.addresses.where((a) => a.isOccupied).length,
      );

  int get totalVacant => totalAddresses - totalOccupied;

  /// Open issue count for a specific housing (0 if unknown).
  int openIssueCountFor(String housingId) =>
      _openIssueCounts[housingId] ?? 0;

  Future<void> load() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();
    try {
      final staffId = _authService.tenantId ?? '';
      final housings = await _apiClient.getStaffHousings(staffId);

      final issueLists = await Future.wait(
        housings.map((h) => _apiClient.getHousingIssues(h.id)),
      );

      final counts = <String, int>{};
      for (var i = 0; i < housings.length; i++) {
        counts[housings[i].id] = issueLists[i]
            .items
            .where((issue) =>
                issue.status != IssueStatus.completed &&
                issue.status != IssueStatus.rejected)
            .length;
      }

      _housings = housings;
      _openIssueCounts = counts;
    } catch (e, s) {
      developer.log(
        'Failed to load admin dashboard',
        name: 'AdminDashboardViewModel',
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
