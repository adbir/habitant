import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/issue.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../l10n/app_localizations.dart';
import 'tenant_home_view_model.dart';

class TenantHomeScreen extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;

  const TenantHomeScreen({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  late final TenantHomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TenantHomeViewModel(
      apiClient: widget.apiClient,
      authService: widget.authService,
    );
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Scaffold(
        appBar: _buildAppBar(context, l10n),
        body: AdaptiveLayout(child: _buildBody(context, l10n)),
        floatingActionButton: _viewModel.isLoading || _viewModel.hasError
            ? null
            : FloatingActionButton(
                onPressed: () => _openReportIssue(context),
                tooltip: l10n.reportIssueTooltip,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  Future<void> _openReportIssue(BuildContext context) async {
    final address = _viewModel.address;
    if (address == null) return;
    await context.push<bool>(
      '/tenant/report-issue',
      extra: {'addressId': address.id},
    );
    _viewModel.refresh();
  }

  AppBar _buildAppBar(BuildContext context, AppLocalizations l10n) {
    final address = _viewModel.address;
    return AppBar(
      title: address == null
          ? Text(l10n.myIssues)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.shortDisplayAddress,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  _viewModel.housing?.name ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Log ud',
          onPressed: widget.authService.logout,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.hasError) {
      return _ErrorState(
        message: l10n.errorLoadFailed,
        retryLabel: l10n.errorRetry,
        onRetry: _viewModel.refresh,
      );
    }

    if (_viewModel.issues.isEmpty) {
      return _EmptyState(l10n: l10n);
    }

    return RefreshIndicator(
      onRefresh: _viewModel.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: _viewModel.issues.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _IssueCard(
          issue: _viewModel.issues[index],
          l10n: l10n,
        ),
      ),
    );
  }
}

// ---- Issue card -------------------------------------------------------------

class _IssueCard extends StatelessWidget {
  final Issue issue;
  final AppLocalizations l10n;

  const _IssueCard({required this.issue, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: () =>
            context.push('/tenant/issues/${issue.id}', extra: issue),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                    _formatDate(issue.createdAt, l10n),
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                issue.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(color: colors.onSurface),
              ),
              if (issue.assignedToName != null) ...[
                const SizedBox(height: 6),
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
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return l10n.today;
    if (diff.inDays == 1) return l10n.yesterday;
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return DateFormat.MMMd().format(date);
  }
}

class _StatusChip extends StatelessWidget {
  final IssueStatus status;
  final AppLocalizations l10n;

  const _StatusChip({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (bg, fg, label) = _style(colors, l10n);
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

  (Color, Color, String) _style(ColorScheme colors, AppLocalizations l10n) =>
      switch (status) {
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

// ---- Empty and error states -------------------------------------------------

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: colors.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noIssuesYet,
              style: text.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noIssuesYetSubtitle,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 64, color: colors.outlineVariant),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
