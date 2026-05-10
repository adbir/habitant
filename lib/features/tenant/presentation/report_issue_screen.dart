import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../l10n/app_localizations.dart';
import 'report_issue_view_model.dart';

class ReportIssueScreen extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;
  final String addressId;

  const ReportIssueScreen({
    super.key,
    required this.apiClient,
    required this.authService,
    required this.addressId,
  });

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  late final ReportIssueViewModel _viewModel;
  final _descriptionController = TextEditingController();
  final _alternativePhoneController = TextEditingController();
  final _alternativePhoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = ReportIssueViewModel(
      apiClient: widget.apiClient,
      authService: widget.authService,
      addressId: widget.addressId,
    );
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _descriptionController.dispose();
    _alternativePhoneController.dispose();
    _alternativePhoneFocusNode.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel.submitted && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _pickPhotos() async {
    if (!_viewModel.canAddPhotos) return;
    try {
      final picked = await ImagePicker().pickMultiImage();
      if (picked.isEmpty) return;
      final photos = await Future.wait(
        picked.map((f) async => ((await f.readAsBytes()), f.name)),
      );
      _viewModel.addPhotos(photos);
    } catch (e, s) {
      developer.log(
        'Photo picker failed',
        name: 'ReportIssueScreen',
        error: e,
        stackTrace: s,
      );
    }
  }

  void _submit() => _viewModel.submit(
        _descriptionController.text,
        _alternativePhoneController.text,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportIssueTitle)),
      body: AdaptiveLayout(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _IssueForm(
                  l10n: l10n,
                  descriptionController: _descriptionController,
                  alternativePhoneController: _alternativePhoneController,
                  alternativePhoneFocusNode: _alternativePhoneFocusNode,
                  viewModel: _viewModel,
                  onSubmit: _submit,
                  onAddPhotos: _pickPhotos,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Form -------------------------------------------------------------------

class _IssueForm extends StatelessWidget {
  final AppLocalizations l10n;
  final TextEditingController descriptionController;
  final TextEditingController alternativePhoneController;
  final FocusNode alternativePhoneFocusNode;
  final ReportIssueViewModel viewModel;
  final VoidCallback onSubmit;
  final VoidCallback onAddPhotos;

  const _IssueForm({
    required this.l10n,
    required this.descriptionController,
    required this.alternativePhoneController,
    required this.alternativePhoneFocusNode,
    required this.viewModel,
    required this.onSubmit,
    required this.onAddPhotos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: descriptionController,
          maxLines: null,
          minLines: 5,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            labelText: l10n.descriptionLabel,
            hintText: l10n.descriptionHint,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        _PhotoSection(
          photos: viewModel.photos,
          canAdd: viewModel.canAddPhotos,
          isLoading: viewModel.isLoading,
          onAdd: onAddPhotos,
          onRemove: viewModel.removePhoto,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.alternativeContactHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: alternativePhoneController,
          focusNode: alternativePhoneFocusNode,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: l10n.alternativeContactPhoneLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        if (viewModel.error != null) ...[
          const SizedBox(height: 12),
          _ErrorText(message: _errorText(l10n, viewModel.error!)),
        ],
        const SizedBox(height: 32),
        FilledButton(
          onPressed: viewModel.isLoading ? null : onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: viewModel.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.submitIssueButton),
        ),
      ],
    );
  }

  String _errorText(AppLocalizations l10n, ReportIssueError error) =>
      switch (error) {
        ReportIssueError.descriptionEmpty => l10n.errorDescriptionEmpty,
        ReportIssueError.uploadFailed => l10n.errorPhotoUploadFailed,
        ReportIssueError.generic => l10n.errorGeneric,
      };
}

// ---- Photo section ----------------------------------------------------------

class _PhotoSection extends StatelessWidget {
  final List<SelectedPhoto> photos;
  final bool canAdd;
  final bool isLoading;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _PhotoSection({
    required this.photos,
    required this.canAdd,
    required this.isLoading,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < photos.length; i++)
          _PhotoTile(
            photo: photos[i],
            onRemove: isLoading ? null : () => onRemove(i),
          ),
        if (canAdd && !isLoading) _AddPhotoTile(onTap: onAdd),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final SelectedPhoto photo;
  final VoidCallback? onRemove;

  const _PhotoTile({required this.photo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(photo.previewBytes, fit: BoxFit.cover),
          ),
          if (photo.status != PhotoUploadStatus.done)
            _UploadOverlay(status: photo.status),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UploadOverlay extends StatelessWidget {
  final PhotoUploadStatus status;

  const _UploadOverlay({required this.status});

  @override
  Widget build(BuildContext context) {
    final isFailed = status == PhotoUploadStatus.failed;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: isFailed
            ? Colors.red.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: isFailed
              ? const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 32,
                )
              : const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          border: Border.all(color: colors.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.add_a_photo_outlined,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ---- Shared helpers ---------------------------------------------------------

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 13,
      ),
    );
  }
}
