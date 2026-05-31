import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/issue.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_mode_service.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../l10n/app_localizations.dart';
import 'maintenance_dashboard_view_model.dart';

class MaintenanceDashboardScreen extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;
  final ThemeModeService themeModeService;

  const MaintenanceDashboardScreen({
    super.key,
    required this.apiClient,
    required this.authService,
    required this.themeModeService,
  });

  @override
  State<MaintenanceDashboardScreen> createState() =>
      _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState
    extends State<MaintenanceDashboardScreen> {
  late final MaintenanceDashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MaintenanceDashboardViewModel(
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.maintenanceTitle),
        actions: [
          if (kDebugMode)
            ListenableBuilder(
              listenable: widget.themeModeService,
              builder: (context, _) => Switch(
                value: widget.themeModeService.isDark,
                onChanged: (_) => widget.themeModeService.toggle(),
                thumbIcon: WidgetStateProperty.resolveWith((states) {
                  return Icon(
                    widget.themeModeService.isDark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    size: 16,
                  );
                }),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: l10n.inviteCreateTitle,
            onPressed: () => context.push('/staff/invite'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logoutTooltip,
            onPressed: widget.authService.logout,
          ),
        ],
      ),
      body: AdaptiveLayout(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => Row(
            children: [
              _StatusSidebar(viewModel: _viewModel, l10n: l10n),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: _buildBody(context, l10n)),
            ],
          ),
        ),
      ),
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

    final issues = _viewModel.filteredIssues;
    if (issues.isEmpty) {
      return _EmptyState(message: l10n.noIssuesFound);
    }

    return RefreshIndicator(
      onRefresh: _viewModel.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: issues.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final issue = issues[index];
          return _IssueCard(
            issue: issue,
            address: _viewModel.addressDisplayFor(issue),
            housingName: _viewModel.housingNameFor(issue),
            l10n: l10n,
            onTap: () => context.push(
              '/staff/issues/${issue.id}',
              extra: issue,
            ),
          );
        },
      ),
    );
  }
}

// ---- Status sidebar ---------------------------------------------------------

class _StatusSidebar extends StatelessWidget {
  final MaintenanceDashboardViewModel viewModel;
  final AppLocalizations l10n;

  const _StatusSidebar({required this.viewModel, required this.l10n});

  String _label(IssueStatusFilter f) => switch (f) {
        IssueStatusFilter.all => l10n.filterAll,
        IssueStatusFilter.pending => l10n.issueStatusPending,
        IssueStatusFilter.assigned => l10n.issueStatusAssigned,
        IssueStatusFilter.inProgress => l10n.issueStatusInProgress,
        IssueStatusFilter.completed => l10n.issueStatusCompleted,
        IssueStatusFilter.rejected => l10n.issueStatusRejected,
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 88,
      color: colors.surfaceContainerLow,
      child: Column(
        children: IssueStatusFilter.values.map((filter) {
          return _SidebarTab(
            label: _label(filter),
            count: viewModel.countFor(filter),
            selected: viewModel.filter == filter,
            onTap: () => viewModel.setFilter(filter),
          );
        }).toList(),
      ),
    );
  }
}

class _SidebarTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? colors.primary : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Issue card -------------------------------------------------------------

class _IssueCard extends StatelessWidget {
  final Issue issue;
  final String address;
  final String housingName;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _IssueCard({
    required this.issue,
    required this.address,
    required this.housingName,
    required this.l10n,
    required this.onTap,
  });

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
        onTap: onTap,
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
              if (address.isNotEmpty || housingName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (housingName.isNotEmpty)
                      Text(
                        housingName,
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
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

// ---- Empty and error states -------------------------------------------------

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
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
            message,
            style: text.titleMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
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
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: colors.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
