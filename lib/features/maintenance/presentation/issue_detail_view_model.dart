import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/models/address.dart';
import '../../../core/models/issue.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

/// Drives the issue detail screen for maintenance workers.
class IssueDetailViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  /// The currently displayed issue; starts with the value passed from the
  /// dashboard list and is replaced on each successful comment submission.
  Issue _issue;

  Address? _address;
  bool _isLoadingAddress = false;
  bool _addressError = false;
  bool _isSubmittingComment = false;

  IssueDetailViewModel({
    required ApiClient apiClient,
    required AuthService authService,
    required Issue initialIssue,
  })  : _apiClient = apiClient,
        _issue = initialIssue;

  Issue get issue => _issue;
  Address? get address => _address;
  bool get isLoadingAddress => _isLoadingAddress;
  bool get addressError => _addressError;
  bool get isSubmittingComment => _isSubmittingComment;

  Future<void> loadAddress() async {
    _isLoadingAddress = true;
    _addressError = false;
    notifyListeners();

    try {
      _address = await _apiClient.getAddress(
        _issue.housingId,
        _issue.addressId,
      );
    } on ApiException catch (_) {
      _addressError = true;
    } catch (e, s) {
      developer.log(
        'Failed to load address for issue ${_issue.id}',
        name: 'IssueDetailViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _addressError = true;
    } finally {
      _isLoadingAddress = false;
      notifyListeners();
    }
  }

  /// Submits a comment and updates the local issue state on success.
  Future<void> addComment(String body, bool isPrivate) async {
    if (body.trim().isEmpty) return;

    _isSubmittingComment = true;
    notifyListeners();

    try {
      _issue = await _apiClient.addIssueComment(
        _issue.id,
        body.trim(),
        isPrivate,
      );
    } on ApiException catch (_) {
      // Let the UI continue — the comment just didn't save.
    } catch (e, s) {
      developer.log(
        'Failed to add comment on issue ${_issue.id}',
        name: 'IssueDetailViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
    } finally {
      _isSubmittingComment = false;
      notifyListeners();
    }
  }
}
