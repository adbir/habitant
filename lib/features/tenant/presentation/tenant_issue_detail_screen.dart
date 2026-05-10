import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/address.dart';
import '../../../core/models/issue.dart';
import '../../../core/models/issue_comment.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../l10n/app_localizations.dart';

class TenantIssueDetailScreen extends StatefulWidget {
  final ApiClient apiClient;
  final Issue issue;

  const TenantIssueDetailScreen({
    super.key,
    required this.apiClient,
    required this.issue,
  });

  @override
  State<TenantIssueDetailScreen> createState() =>
      _TenantIssueDetailScreenState();
}

class _TenantIssueDetailScreenState extends State<TenantIssueDetailScreen> {
  Address? _address;
  bool _loadingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    try {
      final addr = await widget.apiClient.getAddress(
        widget.issue.housingId,
        widget.issue.addressId,
      );
      if (mounted) setState(() { _address = addr; _loadingAddress = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final issue = widget.issue;
    final publicComments =
        issue.comments.where((c) => !c.isPrivate).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.issueDetailTitle)),
      body: AdaptiveLayout(
        child: SingleChildScrollView(
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
              _LocationCard(
                address: _address,
                isLoading: _loadingAddress,
                issue: issue,
                l10n: l10n,
              ),
              const SizedBox(height: 16),
              _SectionTitle(l10n.commentsSection),
              if (publicComments.isEmpty)
                _EmptySection(message: l10n.noCommentsYet)
              else
                ...publicComments.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CommentBubble(comment: c),
                  ),
                ),
            ],
          ),
        ),
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
                color:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
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
  final Address? address;
  final bool isLoading;
  final Issue issue;
  final AppLocalizations l10n;

  const _LocationCard({
    required this.address,
    required this.isLoading,
    required this.issue,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget addressContent;
    if (isLoading) {
      addressContent = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      addressContent = Text(
        address?.displayAddress ?? issue.addressId,
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
                Icon(Icons.phone_outlined, size: 16, color: colors.primary),
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

// ---- Comment bubble (public only) -------------------------------------------

class _CommentBubble extends StatelessWidget {
  final IssueComment comment;

  const _CommentBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.secondary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (comment.authorName != null)
                Text(
                  comment.authorName!,
                  style: text.labelSmall?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const Spacer(),
              Text(
                DateFormat.MMMd().add_Hm().format(comment.createdAt),
                style: text.labelSmall?.copyWith(
                  color: colors.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.body,
            style: text.bodyMedium?.copyWith(
              color: colors.onSecondaryContainer,
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
