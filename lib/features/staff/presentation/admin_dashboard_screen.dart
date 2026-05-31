import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/housing.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_mode_service.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../l10n/app_localizations.dart';
import 'admin_dashboard_view_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;
  final ThemeModeService themeModeService;

  const AdminDashboardScreen({
    super.key,
    required this.apiClient,
    required this.authService,
    required this.themeModeService,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminDashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AdminDashboardViewModel(
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
        appBar: AppBar(
          title: Text(l10n.adminDashboardTitle),
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
              icon: const Icon(Icons.logout),
              tooltip: 'Log ud',
              onPressed: widget.authService.logout,
            ),
          ],
        ),
        body: AdaptiveLayout(
          child: _buildBody(context, l10n),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.errorLoadFailed),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _viewModel.refresh,
              child: Text(l10n.errorRetry),
            ),
          ],
        ),
      );
    }

    if (_viewModel.housings.isEmpty) {
      return Center(
        child: Text(
          l10n.adminNoHousings,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _viewModel.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SummaryRow(viewModel: _viewModel, l10n: l10n),
          const SizedBox(height: 24),
          Text(
            l10n.adminHousingsSectionTitle,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 8),
          ..._viewModel.housings.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HousingCard(
                housing: h,
                openIssues: _viewModel.openIssueCountFor(h.id),
                onTap: () =>
                    context.push('/admin/housing/${h.id}', extra: h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Summary row -----------------------------------------------------------

class _SummaryRow extends StatelessWidget {
  final AdminDashboardViewModel viewModel;
  final AppLocalizations l10n;

  const _SummaryRow({required this.viewModel, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: l10n.adminStatTotalAddresses,
            value: '${viewModel.totalAddresses}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: l10n.adminStatOccupied,
            value: '${viewModel.totalOccupied}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: l10n.adminStatVacant,
            value: '${viewModel.totalVacant}',
            highlight: viewModel.totalVacant > 0,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight
            ? colors.errorContainer.withValues(alpha: 0.3)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: highlight ? colors.error : colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ---- Housing card ----------------------------------------------------------

class _HousingCard extends StatelessWidget {
  final Housing housing;
  final int openIssues;
  final VoidCallback onTap;

  const _HousingCard({
    required this.housing,
    required this.openIssues,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final occupied =
        housing.addresses.where((a) => a.isOccupied).length;
    final total = housing.addresses.length;

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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      housing.name,
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      housing.city,
                      style: text.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _OccupancyBadge(occupied: occupied, total: total),
                        if (openIssues > 0) ...[
                          const SizedBox(width: 6),
                          _IssuesBadge(count: openIssues),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _OccupancyBadge extends StatelessWidget {
  final int occupied;
  final int total;

  const _OccupancyBadge({required this.occupied, required this.total});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$occupied/$total beboet',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _IssuesBadge extends StatelessWidget {
  final int count;

  const _IssuesBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count åbne',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
