import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/models/issue.dart';
import '../../../core/services/api_client.dart';

/// Open issues for a single housing association, with pagination.
///
/// Loads the first page on [load]; call [loadMore] to append the next page.
/// [refresh] resets to page 0 and reloads.
///
/// Only open issues are fetched by default (pending, assigned, inProgress).
class HousingIssuesViewModel extends ChangeNotifier {
  static const _pageSize = 25;
  static const _openStatuses = {
    IssueStatus.pending,
    IssueStatus.assigned,
    IssueStatus.inProgress,
  };

  final ApiClient _apiClient;
  final String _housingId;

  List<Issue> _issues = const [];
  int _page = 0;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;

  HousingIssuesViewModel({
    required ApiClient apiClient,
    required String housingId,
  })  : _apiClient = apiClient,
        _housingId = housingId;

  List<Issue> get issues => List.unmodifiable(_issues);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool get hasError => _hasError;

  Future<void> load() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();
    try {
      final result = await _apiClient.getHousingIssues(
        _housingId,
        statuses: _openStatuses,
        page: 0,
        pageSize: _pageSize,
      );
      _issues = result.items;
      _hasMore = result.hasMore;
      _page = 0;
    } catch (e, s) {
      developer.log(
        'Failed to load housing issues',
        name: 'HousingIssuesViewModel',
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

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final result = await _apiClient.getHousingIssues(
        _housingId,
        statuses: _openStatuses,
        page: _page + 1,
        pageSize: _pageSize,
      );
      _issues = [..._issues, ...result.items];
      _hasMore = result.hasMore;
      _page++;
    } catch (e, s) {
      developer.log(
        'Failed to load more housing issues',
        name: 'HousingIssuesViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => load();
}
