import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';

import '../../../core/models/address.dart';
import '../../../core/models/tenant_profile.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../l10n/app_localizations.dart';
import 'address_detail_view_model.dart';
import 'address_widgets.dart';
import 'housing_detail_view_model.dart';
import 'tenancy_issues_screen.dart';

class AddressDetailScreen extends StatefulWidget {
  final Address initialAddress;
  final ApiClient apiClient;

  const AddressDetailScreen({
    super.key,
    required this.initialAddress,
    required this.apiClient,
  });

  @override
  State<AddressDetailScreen> createState() => _AddressDetailScreenState();
}

class _AddressDetailScreenState extends State<AddressDetailScreen> {
  late final AddressDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AddressDetailViewModel(
      apiClient: widget.apiClient,
      address: widget.initialAddress,
    );
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _copyLink(String link, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.inviteLinkCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialAddress.shortDisplayAddress)),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final l10n = AppLocalizations.of(context)!;

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

          return AdaptiveLayout(child: _buildContent(context, l10n));
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final address = _viewModel.address;

    return RefreshIndicator(
      onRefresh: _viewModel.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status chip
            AddressStatusChip(status: _viewModel.status, l10n: l10n),
            const SizedBox(height: 20),

            // Occupancy section
            ..._buildStatusSection(context, l10n, colors, text),

            // History section
            const SizedBox(height: 28),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Text(
              l10n.addressDetailHistorySection.toUpperCase(),
              style: text.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            if (address.history.isEmpty)
              Text(
                l10n.addressDetailNoHistory,
                style:
                    text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              )
            else
              ...address.history.map(
                (record) => _HistoryTile(
                  record: record,
                  profile: _viewModel.profileFor(record.tenantId),
                  l10n: l10n,
                  onViewIssues: record.issueIds.isEmpty
                      ? null
                      : () => context.push(
                            '/admin/housing/${address.housingId}/address/${address.id}/tenancy-issues',
                            extra: TenancyIssuesArgs(
                              issueIds: record.issueIds,
                              addressShortName: address.shortDisplayAddress,
                              tenantName: _viewModel
                                  .profileFor(record.tenantId)
                                  ?.name,
                            ),
                          ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatusSection(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colors,
    TextTheme text,
  ) {
    switch (_viewModel.status) {
      case AddressStatus.occupied:
        final tenants = _viewModel.currentTenants;
        if (tenants.isEmpty) {
          return [
            Text(
              l10n.addressNoTenants,
              style:
                  text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ];
        }
        return [
          Text(
            l10n.addressTenantsSection,
            style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...tenants.map((t) => TenantTile(tenant: t)),
        ];

      case AddressStatus.invitationPending:
        final inv = _viewModel.invitation!;
        final link = _viewModel.invitationLink(inv);
        return [
          Text(
            l10n.addressStatusInvitationPending,
            style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          LinkBox(link: link),
          const SizedBox(height: 8),
          Text(
            '${l10n.addressInviteExpires} ${_fmtDate(inv.expiresAt)}',
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyLink(link, l10n),
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(l10n.inviteCopyLink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _viewModel.isCancellingInvitation
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton.tonal(
                        onPressed: _viewModel.cancelInvitation,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.errorContainer,
                          foregroundColor: colors.onErrorContainer,
                        ),
                        child: Text(l10n.addressCancelInvitationFull),
                      ),
              ),
            ],
          ),
        ];

      case AddressStatus.vacant:
        return [
          Text(
            l10n.addressVacantHint,
            style:
                text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _viewModel.isCreatingInvitation
              ? const Center(child: CircularProgressIndicator())
              : FilledButton.icon(
                  onPressed: _viewModel.createInvitation,
                  icon: const Icon(Icons.send),
                  label: Text(l10n.addressInviteTenant),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
        ];
    }
  }

  static String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ---- History tile -----------------------------------------------------------

class _HistoryTile extends StatelessWidget {
  final TenancyRecord record;
  final TenantProfile? profile;
  final AppLocalizations l10n;
  final VoidCallback? onViewIssues;

  const _HistoryTile({
    required this.record,
    required this.profile,
    required this.l10n,
    this.onViewIssues,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final isActive = record.isActive;

    final displayName = profile?.name ?? profile?.email;
    final initials = _initials(displayName ?? '?');
    final avatarBg = isActive
        ? colors.secondaryContainer
        : colors.surfaceContainerHighest;
    final avatarFg = isActive
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onViewIssues,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: avatarBg,
                child: Text(
                  initials,
                  style: text.labelSmall?.copyWith(
                    color: avatarFg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName ?? '—',
                            style: text.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l10n.addressDetailCurrentTenant,
                              style: text.labelSmall?.copyWith(
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.addressDetailMovedIn}: ${_fmtDate(record.movedInAt)}',
                      style: text.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    if (!isActive)
                      Text(
                        '${l10n.addressDetailMovedOut}: ${_fmtDate(record.movedOutAt!)}',
                        style: text.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    if (record.issueIds.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.addressDetailIssueCount(record.issueIds.length),
                        style: text.bodySmall?.copyWith(
                          color: onViewIssues != null
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          decoration: onViewIssues != null
                              ? TextDecoration.underline
                              : null,
                          decorationColor: colors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onViewIssues != null)
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  static String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }
}
