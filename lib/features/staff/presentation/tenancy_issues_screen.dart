import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/issue.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../l10n/app_localizations.dart';

/// Arguments passed via GoRouter's [extra] when pushing to the tenancy
/// issues route. All fields are available at the push site, so no additional
/// network calls are needed to render the screen header.
class TenancyIssuesArgs {
  final List<String> issueIds;

  /// Display name of the tenant whose tenancy this covers.
  final String? tenantName;

  /// Short address label for context in the AppBar subtitle.
  final String addressShortName;

  const TenancyIssuesArgs({
    required this.issueIds,
    required this.addressShortName,
    this.tenantName,
  });
}

class TenancyIssuesScreen extends StatefulWidget {
  final TenancyIssuesArgs args;
  final ApiClient apiClient;

  const TenancyIssuesScreen({
    super.key,
    required this.args,
    required this.apiClient,
  });

  @override
  State<TenancyIssuesScreen> createState() => _TenancyIssuesScreenState();
}

class _TenancyIssuesScreenState extends State<TenancyIssuesScreen> {
  late final Future<List<Issue>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.wait(
      widget.args.issueIds.map((id) => widget.apiClient.getIssue(id)),
    ).then(
      (issues) => issues..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tenantName = widget.args.tenantName;

    return Scaffold(
      appBar: AppBar(
        title: Text(tenantName ?? l10n.maintenanceTitle),
        bottom: tenantName != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.args.addressShortName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: AdaptiveLayout(
        child: FutureBuilder<List<Issue>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.errorLoadFailed),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() {
                        _future = Future.wait(
                          widget.args.issueIds
                              .map((id) => widget.apiClient.getIssue(id)),
                        ).then(
                          (issues) => issues
                            ..sort(
                              (a, b) => b.createdAt.compareTo(a.createdAt),
                            ),
                        );
                      }),
                      child: Text(l10n.errorRetry),
                    ),
                  ],
                ),
              );
            }

            final issues = snapshot.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              itemCount: issues.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IssueCard(
                  issue: issues[index],
                  onTap: () => context.push(
                    '/staff/issues/${issues[index].id}',
                    extra: issues[index],
                  ),
                  l10n: l10n,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---- Issue card -------------------------------------------------------------

class IssueCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const IssueCard({
    super.key,
    required this.issue,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final (chipBg, chipFg, chipLabel) = switch (issue.status) {
      IssueStatus.pending => (
          colors.errorContainer,
          colors.onErrorContainer,
          l10n.issueStatusPending,
        ),
      IssueStatus.assigned => (
          colors.secondaryContainer,
          colors.onSecondaryContainer,
          l10n.issueStatusAssigned,
        ),
      IssueStatus.inProgress => (
          colors.tertiaryContainer,
          colors.onTertiaryContainer,
          l10n.issueStatusInProgress,
        ),
      IssueStatus.completed => (
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant,
          l10n.issueStatusCompleted,
        ),
      IssueStatus.rejected => (
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant,
          l10n.issueStatusRejected,
        ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status chip in a fixed-width column so descriptions align
            SizedBox(
              width: 88,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  chipLabel,
                  textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(color: chipFg),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmtDate(issue.createdAt),
                    style: text.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  if (issue.assignedToName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.issueHandledBy(issue.assignedToName!),
                      style: text.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
