import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

enum ReportIssueError { descriptionEmpty, uploadFailed, generic }

enum PhotoUploadStatus { uploading, done, failed }

/// A photo selected by the user, ready for display.
class SelectedPhoto {
  final Uint8List previewBytes;
  final PhotoUploadStatus status;

  const SelectedPhoto({required this.previewBytes, required this.status});
}

class _PhotoUpload {
  final Uint8List previewBytes;
  PhotoUploadStatus status = PhotoUploadStatus.uploading;
  String? uploadedUrl;
  bool abandoned = false;
  final Future<String> future;

  _PhotoUpload({required this.previewBytes, required this.future});

  SelectedPhoto toSelectedPhoto() =>
      SelectedPhoto(previewBytes: previewBytes, status: status);
}

/// Drives the report-issue form.
///
/// Photos are compressed to WebP and uploaded immediately when selected,
/// so the network round-trip overlaps with the user filling in the description.
class ReportIssueViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthService _authService;
  final String _addressId;

  static const int maxPhotos = 5;
  static const _uuid = Uuid();

  bool _isLoading = false;
  bool _submitted = false;
  bool _disposed = false;
  ReportIssueError? _error;
  final List<_PhotoUpload> _uploads = [];

  ReportIssueViewModel({
    required ApiClient apiClient,
    required AuthService authService,
    required String addressId,
  })  : _apiClient = apiClient,
        _authService = authService,
        _addressId = addressId;

  bool get isLoading => _isLoading;
  bool get submitted => _submitted;
  ReportIssueError? get error => _error;
  List<SelectedPhoto> get photos =>
      List.unmodifiable(_uploads.map((u) => u.toSelectedPhoto()));
  bool get canAddPhotos => _uploads.length < maxPhotos;

  void addPhotos(List<(Uint8List, String)> incoming) {
    final slots = maxPhotos - _uploads.length;
    if (slots <= 0) return;
    for (final (bytes, _) in incoming.take(slots)) {
      _startUpload(bytes);
    }
    notifyListeners();
  }

  void removePhoto(int index) {
    _uploads[index].abandoned = true;
    _uploads.removeAt(index);
    notifyListeners();
  }

  void _startUpload(Uint8List rawBytes) {
    final filename = '${_uuid.v4()}.webp';
    final future = _compressAndUpload(rawBytes, filename);
    final upload = _PhotoUpload(previewBytes: rawBytes, future: future);
    _uploads.add(upload);

    future.then((url) {
      if (_disposed || upload.abandoned) return;
      upload.status = PhotoUploadStatus.done;
      upload.uploadedUrl = url;
      notifyListeners();
    }).catchError((Object e, StackTrace s) {
      if (_disposed || upload.abandoned) return;
      developer.log(
        'Photo upload failed',
        name: 'ReportIssueViewModel',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      upload.status = PhotoUploadStatus.failed;
      notifyListeners();
    });
  }

  Future<String> _compressAndUpload(
    Uint8List rawBytes,
    String filename,
  ) async {
    final compressed = await FlutterImageCompress.compressWithList(
      rawBytes,
      format: CompressFormat.webp,
      quality: 85,
      minWidth: 1920,
      minHeight: 1920,
    );
    return _apiClient.uploadIssuePhoto(compressed, filename);
  }

  /// Submits the issue. If photos are still uploading, waits for them first.
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
      final pendingFutures = _uploads
          .where((u) => u.status == PhotoUploadStatus.uploading)
          .map((u) => u.future)
          .toList();

      if (pendingFutures.isNotEmpty) {
        try {
          await Future.wait(pendingFutures);
        } catch (_) {
          // Failures are tracked per-upload; handled below.
        }
      }

      if (_uploads.any((u) => u.status == PhotoUploadStatus.failed)) {
        _error = ReportIssueError.uploadFailed;
        return;
      }

      final photoUrls = _uploads.map((u) => u.uploadedUrl!).toList();

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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setError(ReportIssueError error) {
    _error = error;
    notifyListeners();
  }
}
