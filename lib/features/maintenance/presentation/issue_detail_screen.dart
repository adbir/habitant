import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/issue.dart';
import '../../../core/models/issue_comment.dart';
import '../../../core/models/maintenance_update.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../l10n/app_localizations.dart';
import 'issue_detail_view_model.dart';

class IssueDetailScreen extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;
  final Issue initialIssue;

  const IssueDetailScreen({
    super.key,
    required this.apiClient,
    required this.authService,
    required this.initialIssue,
  });

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  late final IssueDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = IssueDetailViewModel(
      apiClient: widget.apiClient,
      authService: widget.authService,
      initialIssue: widget.initialIssue,
    );
    _viewModel.loadAddress();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.issueDetailTitle)),
      body: AdaptiveLayout(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => Column(
            children: [
              Expanded(
                child: _IssueContent(
                  viewModel: _viewModel,
                  l10n: l10n,
                ),
              ),
              _CommentInput(
                isSubmitting: _viewModel.isSubmittingComment,
                onSubmit: _viewModel.addComment,
                l10n: l10n,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Scrollable content -----------------------------------------------------

class _IssueContent extends StatelessWidget {
  final IssueDetailViewModel viewModel;
  final AppLocalizations l10n;

  const _IssueContent({required this.viewModel, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final issue = viewModel.issue;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IssueHeader(issue: issue, l10n: l10n),
          const SizedBox(height: 16),
          if (issue.photoUrls.isNotEmpty) ...[
            _PhotosRow(urls: issue.photoUrls),
            const SizedBox(height: 16),
          ],
          _LocationCard(viewModel: viewModel, issue: issue, l10n: l10n),
          const SizedBox(height: 16),
          if (issue.updates.isNotEmpty) ...[
            _SectionTitle(l10n.maintenanceUpdatesSection),
            ...issue.updates.map(
              (u) => _UpdateCard(update: u, l10n: l10n),
            ),
            const SizedBox(height: 16),
          ],
          _SectionTitle(l10n.commentsSection),
          if (issue.comments.isEmpty)
            _EmptySection(message: l10n.noCommentsYet)
          else
            ...issue.comments.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CommentBubble(comment: c, l10n: l10n),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---- Issue header -----------------------------------------------------------

class _IssueHeader extends StatelessWidget {
  final Issue issue;
  final AppLocalizations l10n;

  const _IssueHeader({required this.issue, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusChip(status: issue.status, l10n: l10n),
            if (issue.needAssistance) ...[
              const SizedBox(width: 8),
              _NeedsAssistanceBadge(l10n: l10n),
            ],
            const Spacer(),
            Text(
              DateFormat.yMMMd().format(issue.createdAt),
              style: text.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (issue.assignedToName != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                issue.assignedToName!,
                style: text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Text(issue.description, style: text.bodyLarge),
      ],
    );
  }
}

// ---- Photos -----------------------------------------------------------------

class _PhotosRow extends StatelessWidget {
  final List<String> urls;

  const _PhotosRow({required this.urls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            urls[index],
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: 120,
                height: 120,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: 120,
              height: 120,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Location card ----------------------------------------------------------

class _LocationCard extends StatelessWidget {
  final IssueDetailViewModel viewModel;
  final Issue issue;
  final AppLocalizations l10n;

  const _LocationCard({
    required this.viewModel,
    required this.issue,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget addressContent;
    if (viewModel.isLoadingAddress) {
      addressContent = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (viewModel.addressError || viewModel.address == null) {
      addressContent = Text(
        issue.addressId,
        style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      );
    } else {
      addressContent = Text(
        viewModel.address!.displayAddress,
        style: text.bodyMedium,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.addressSection,
            style: text.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          addressContent,
          if (issue.alternativeContactPhone != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.alternativePhoneLabel,
              style: text.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  issue.alternativeContactPhone!,
                  style: text.bodyMedium?.copyWith(color: colors.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---- Maintenance update card ------------------------------------------------

class _UpdateCard extends StatelessWidget {
  final MaintenanceUpdate update;
  final AppLocalizations l10n;

  const _UpdateCard({required this.update, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.build_outlined,
                size: 14,
                color: colors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat.yMMMd().format(update.completedAt),
                style: text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            update.description,
            style: text.bodyMedium?.copyWith(color: colors.onSurface),
          ),
          if (update.proofPhotoUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PhotosRow(urls: update.proofPhotoUrls),
          ],
        ],
      ),
    );
  }
}

// ---- Comment bubble ---------------------------------------------------------

class _CommentBubble extends StatelessWidget {
  final IssueComment comment;
  final AppLocalizations l10n;

  const _CommentBubble({required this.comment, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isPrivate = comment.isPrivate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPrivate
            ? colors.surfaceContainerHigh
            : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrivate ? colors.outline : colors.secondary,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPrivate ? Icons.lock_outline : Icons.person_outline,
                size: 14,
                color: isPrivate
                    ? colors.onSurfaceVariant
                    : colors.onSecondaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                isPrivate ? l10n.internalCommentLabel : l10n.publicCommentLabel,
                style: text.labelSmall?.copyWith(
                  color: isPrivate
                      ? colors.onSurfaceVariant
                      : colors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (comment.authorName != null) ...[
                const SizedBox(width: 6),
                Text(
                  '· ${comment.authorName}',
                  style: text.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                DateFormat.MMMd().add_Hm().format(comment.createdAt),
                style: text.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment.body, style: text.bodyMedium),
        ],
      ),
    );
  }
}

// ---- Comment input ----------------------------------------------------------

class _CommentInput extends StatefulWidget {
  final bool isSubmitting;
  final Future<void> Function(String body, bool isPrivate) onSubmit;
  final AppLocalizations l10n;

  const _CommentInput({
    required this.isSubmitting,
    required this.onSubmit,
    required this.l10n,
  });

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _controller = TextEditingController();
  bool _isPrivate = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text, _isPrivate);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: _isPrivate ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                widget.l10n.internalNoteToggle,
                style: text.bodySmall?.copyWith(
                  color:
                      _isPrivate ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Switch(
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: widget.l10n.commentHint,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              widget.isSubmitting
                  ? const SizedBox(
                      height: 44,
                      width: 44,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton.filled(
                      icon: const Icon(Icons.send),
                      tooltip: widget.l10n.sendButton,
                      onPressed: _submit,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Shared helpers ---------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;

  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IssueStatus status;
  final AppLocalizations l10n;

  const _StatusChip({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (bg, fg, label) = _style(colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  (Color, Color, String) _style(ColorScheme colors) => switch (status) {
        IssueStatus.pending => (
            colors.surfaceContainerHighest,
            colors.onSurfaceVariant,
            l10n.issueStatusPending,
          ),
        IssueStatus.assigned => (
            colors.surfaceContainerHigh,
            colors.onSurface,
            l10n.issueStatusAssigned,
          ),
        IssueStatus.inProgress => (
            const Color(0xFFFFF3E0),
            const Color(0xFFE65100),
            l10n.issueStatusInProgress,
          ),
        IssueStatus.completed => (
            const Color(0xFFE8F5E9),
            const Color(0xFF1B5E20),
            l10n.issueStatusCompleted,
          ),
        IssueStatus.rejected => (
            colors.errorContainer,
            colors.onErrorContainer,
            l10n.issueStatusRejected,
          ),
      };
}

class _NeedsAssistanceBadge extends StatelessWidget {
  final AppLocalizations l10n;

  const _NeedsAssistanceBadge({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_amber_rounded, size: 14, color: colors.error),
        const SizedBox(width: 4),
        Text(
          l10n.needsAssistanceLabel,
          style: TextStyle(
            fontSize: 12,
            color: colors.error,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
