import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

/// Reasons the report-issue form can fail.
enum ReportIssueError { descriptionEmpty, generic }

/// A photo selected by the user, held as raw bytes until upload.
typedef SelectedPhoto = (Uint8List bytes, String filename);

/// Drives the report-issue form.
class ReportIssueViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthService _authService;
  final String _addressId;

  static const int maxPhotos = 5;

  bool _isLoading = false;
  bool _submitted = false;
  ReportIssueError? _error;
  final List<SelectedPhoto> _photos = [];

  ReportIssueViewModel({
    required ApiClient apiClient,
    required AuthService authService,
    required String addressId,
  })  : _apiClient = apiClient,
        _authService = authService,
        _addressId = addressId;

  bool get isLoading => _isLoading;

  /// True once the issue has been successfully submitted.
  bool get submitted => _submitted;
  ReportIssueError? get error => _error;
  List<SelectedPhoto> get photos => List.unmodifiable(_photos);
  bool get canAddPhotos => _photos.length < maxPhotos;

  void addPhotos(List<SelectedPhoto> incoming) {
    final slots = maxPhotos - _photos.length;
    if (slots <= 0) return;
    _photos.addAll(incoming.take(slots));
    notifyListeners();
  }

  void removePhoto(int index) {
    _photos.removeAt(index);
    notifyListeners();
  }

  /// [alternativePhone] is optional — passed as-is when non-empty.
  Future<void> submit(String description, String alternativePhone) async {
    if (description.trim().isEmpty) {
      _setError(ReportIssueError.descriptionEmpty);
      return;
    }

    final tenantId = _authService.tenantId;
    if (tenantId == null) {
      _setError(ReportIssueError.generic);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final photoUrls = await Future.wait(
        _photos.map((p) => _apiClient.uploadIssuePhoto(p.$1, p.$2)),
      );
      await _apiClient.reportIssue(
        tenantId,
        _addressId,
        description.trim(),
        photoUrls,
        alternativeContactPhone:
            alternativePhone.trim().isEmpty ? null : alternativePhone.trim(),
      );
      _submitted = true;
    } on ApiException catch (_) {
      _error = ReportIssueError.generic;
    } catch (e, s) {
      developer.log(
        'Failed to report issue',
        name: 'ReportIssueViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _error = ReportIssueError.generic;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setError(ReportIssueError error) {
    _error = error;
    notifyListeners();
  }
}
