import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/address.dart';
import '../../../core/models/housing.dart';
import '../../../core/models/invitation.dart';
import '../../../core/models/issue.dart';
import '../../../core/models/tenant_profile.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/adaptive_sheet.dart';
import '../../../l10n/app_localizations.dart';
import 'address_widgets.dart';
import 'housing_detail_view_model.dart';
import 'housing_issues_view_model.dart';

class HousingDetailScreen extends StatefulWidget {
  final Housing initialHousing;
  final ApiClient apiClient;
  final AuthService authService;

  const HousingDetailScreen({
    super.key,
    required this.initialHousing,
    required this.apiClient,
    required this.authService,
  });

  @override
  State<HousingDetailScreen> createState() => _HousingDetailScreenState();
}

class _HousingDetailScreenState extends State<HousingDetailScreen> {
  late final HousingDetailViewModel _viewModel;
  late final HousingIssuesViewModel _issuesViewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HousingDetailViewModel(
      apiClient: widget.apiClient,
      authService: widget.authService,
      initialHousing: widget.initialHousing,
    );
    _issuesViewModel = HousingIssuesViewModel(
      apiClient: widget.apiClient,
      housingId: widget.initialHousing.id,
    );
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.load();
    _issuesViewModel.load();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _issuesViewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final inv = _viewModel.createdInvitation;
    if (inv != null && mounted) {
      _showInvitationSheet(inv);
    }
  }

  void _showInvitationSheet(Invitation inv) {
    final l10n = AppLocalizations.of(context)!;
    final link = _viewModel.invitationLink(inv);
    showAdaptiveSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.inviteLinkCreatedTitle,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (inv.address != null) ...[
                const SizedBox(height: 4),
                Text(
                  inv.address!.displayAddress,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              LinkBox(link: link),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.inviteLinkCopied)),
                  );
                  Navigator.of(ctx).pop();
                },
                icon: const Icon(Icons.copy),
                label: Text(l10n.inviteCopyLink),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(_viewModel.clearCreatedInvitation);
  }

  void _showAddressDetail(BuildContext context, Address address) {
    final status = _viewModel.statusFor(address);
    final invitation = _viewModel.invitations
        .where((inv) => inv.addressId == address.id)
        .firstOrNull;
    final link =
        invitation != null ? _viewModel.invitationLink(invitation) : null;

    showAdaptiveSheet<void>(
      context: context,
      builder: (ctx) => _AddressDetailSheet(
        address: address,
        status: status,
        invitation: invitation,
        invitationLink: link,
        apiClient: widget.apiClient,
        onCreateInvitation: () {
          Navigator.of(ctx).pop();
          _viewModel.createInvitation(address.id);
        },
        onCancelInvitation: invitation != null
            ? () {
                Navigator.of(ctx).pop();
                _viewModel.cancelInvitation(invitation.id);
              }
            : null,
        onCopyLink: link != null
            ? () {
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.inviteLinkCopied,
                    ),
                  ),
                );
                Navigator.of(ctx).pop();
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: Text(_viewModel.housing.name),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(68),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 0, 4),
                    child: Text(
                      _viewModel.housing.city,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                    ),
                  ),
                  TabBar(
                    tabs: [
                      Tab(text: l10n.housingAddressesSection),
                      Tab(text: l10n.housingOpenIssuesSection),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: AdaptiveLayout(
            child: _buildBody(context, l10n),
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

    // Sort addresses: occupied first, then pending, then vacant.
    final sorted = [..._viewModel.housing.addresses]..sort((a, b) {
        int rank(Address addr) => switch (_viewModel.statusFor(addr)) {
              AddressStatus.occupied => 0,
              AddressStatus.invitationPending => 1,
              AddressStatus.vacant => 2,
            };
        return rank(a).compareTo(rank(b));
      });

    return TabBarView(
      children: [
        _UnitsTab(
          sorted: sorted,
          viewModel: _viewModel,
          onAddressTap: (address) => context.push(
            '/admin/housing/${address.housingId}/address/${address.id}',
            extra: address,
          ),
          onAddressPeek: (address) => _showAddressDetail(context, address),
        ),
        _IssuesTab(
          viewModel: _issuesViewModel,
          l10n: l10n,
          onIssueTap: (issue) =>
              context.push('/staff/issues/${issue.id}', extra: issue),
        ),
      ],
    );
  }
}

// ---- Units tab --------------------------------------------------------------

class _UnitsTab extends StatelessWidget {
  final List<Address> sorted;
  final HousingDetailViewModel viewModel;
  final ValueChanged<Address> onAddressTap;
  final ValueChanged<Address> onAddressPeek;

  const _UnitsTab({
    required this.sorted,
    required this.viewModel,
    required this.onAddressTap,
    required this.onAddressPeek,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final a = sorted[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AddressRow(
              address: a,
              status: viewModel.statusFor(a),
              invitation: viewModel.invitations
                  .where((inv) => inv.addressId == a.id)
                  .firstOrNull,
              isCancelling: viewModel.invitations
                  .where((inv) => inv.addressId == a.id)
                  .any((inv) => viewModel.isCancelling(inv.id)),
              isCreating: viewModel.isCreating(a.id),
              onInvite: () => viewModel.createInvitation(a.id),
              onCancel: (invId) => viewModel.cancelInvitation(invId),
              onTap: () => onAddressTap(a),
              onPeek: () => onAddressPeek(a),
            ),
          );
        },
      ),
    );
  }
}

// ---- Issues tab -------------------------------------------------------------

class _IssuesTab extends StatelessWidget {
  final HousingIssuesViewModel viewModel;
  final AppLocalizations l10n;
  final ValueChanged<Issue> onIssueTap;

  const _IssuesTab({
    required this.viewModel,
    required this.l10n,
    required this.onIssueTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (viewModel.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.errorLoadFailed),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: viewModel.refresh,
                  child: Text(l10n.errorRetry),
                ),
              ],
            ),
          );
        }

        final issues = viewModel.issues;

        if (issues.isEmpty) {
          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  l10n.housingNoOpenIssues,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        // Extra slot at the end for the load-more spinner.
        final itemCount = issues.length + (viewModel.hasMore ? 1 : 0);

        return RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification && n.metrics.extentAfter < 200) {
                viewModel.loadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index == issues.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final issue = issues[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _IssueTile(
                    issue: issue,
                    onTap: () => onIssueTap(issue),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ---- Address row ------------------------------------------------------------

class _AddressRow extends StatelessWidget {
  final Address address;
  final AddressStatus status;
  final Invitation? invitation;
  final bool isCancelling;
  final bool isCreating;
  final VoidCallback onInvite;
  final ValueChanged<String> onCancel;
  final VoidCallback? onTap;
  final VoidCallback? onPeek;

  const _AddressRow({
    required this.address,
    required this.status,
    required this.invitation,
    required this.isCancelling,
    required this.isCreating,
    required this.onInvite,
    required this.onCancel,
    this.onTap,
    this.onPeek,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.shortDisplayAddress,
                    style:
                        text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  AddressStatusChip(status: status, l10n: l10n),
                ],
              ),
            ),
            const SizedBox(width: 4),
            _AddressAction(
              status: status,
              invitation: invitation,
              isCancelling: isCancelling,
              isCreating: isCreating,
              onInvite: onInvite,
              onCancel: onCancel,
              l10n: l10n,
            ),
            IconButton(
              icon: Icon(
                Icons.info_outline,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
              tooltip: l10n.addressDetailPreviewTooltip,
              onPressed: onPeek,
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressAction extends StatelessWidget {
  final AddressStatus status;
  final Invitation? invitation;
  final bool isCancelling;
  final bool isCreating;
  final VoidCallback onInvite;
  final ValueChanged<String> onCancel;
  final AppLocalizations l10n;

  const _AddressAction({
    required this.status,
    required this.invitation,
    required this.isCancelling,
    required this.isCreating,
    required this.onInvite,
    required this.onCancel,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      AddressStatus.occupied => const SizedBox.shrink(),
      AddressStatus.vacant => isCreating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : FilledButton.tonal(
              onPressed: onInvite,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.addressInviteTenant,
                  style: const TextStyle(fontSize: 13)),
            ),
      AddressStatus.invitationPending => isCancelling
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed:
                  invitation != null ? () => onCancel(invitation!.id) : null,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.addressCancelInvitation,
                  style: const TextStyle(fontSize: 13)),
            ),
    };
  }
}

// ---- Issue tile -------------------------------------------------------------

class _IssueTile extends StatelessWidget {
  final Issue issue;
  final VoidCallback onTap;

  const _IssueTile({required this.issue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final (chipBg, chipFg, label) = switch (issue.status) {
      IssueStatus.pending => (
          colors.errorContainer,
          colors.onErrorContainer,
          'Ny',
        ),
      IssueStatus.assigned => (
          colors.secondaryContainer,
          colors.onSecondaryContainer,
          'Tildelt',
        ),
      IssueStatus.inProgress => (
          colors.tertiaryContainer,
          colors.onTertiaryContainer,
          'I gang',
        ),
      _ => (
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant,
          issue.status.label,
        ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: text.labelSmall?.copyWith(color: chipFg),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                issue.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium,
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ---- Address detail sheet ---------------------------------------------------

class _AddressDetailSheet extends StatelessWidget {
  final Address address;
  final AddressStatus status;
  final Invitation? invitation;
  final String? invitationLink;
  final ApiClient apiClient;
  final VoidCallback onCreateInvitation;
  final VoidCallback? onCancelInvitation;
  final VoidCallback? onCopyLink;

  const _AddressDetailSheet({
    required this.address,
    required this.status,
    required this.apiClient,
    required this.onCreateInvitation,
    this.invitation,
    this.invitationLink,
    this.onCancelInvitation,
    this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              address.shortDisplayAddress,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            AddressStatusChip(status: status, l10n: l10n),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            ..._buildSection(context, l10n, colors, text),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSection(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colors,
    TextTheme text,
  ) {
    switch (status) {
      case AddressStatus.occupied:
        return [_TenantsSection(address: address, apiClient: apiClient, l10n: l10n)];
      case AddressStatus.invitationPending:
        final inv = invitation!;
        final link = invitationLink ?? '';
        return [
          Text(
            l10n.addressStatusInvitationPending,
            style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          LinkBox(link: link),
          const SizedBox(height: 8),
          Text(
            '${l10n.addressInviteExpires} ${_formatDate(inv.expiresAt)}',
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopyLink,
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(l10n.inviteCopyLink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onCancelInvitation,
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
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreateInvitation,
            icon: const Icon(Icons.send),
            label: Text(l10n.addressInviteTenant),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ];
    }
  }

  static String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ---- Tenants section --------------------------------------------------------

class _TenantsSection extends StatelessWidget {
  final Address address;
  final ApiClient apiClient;
  final AppLocalizations l10n;

  const _TenantsSection({
    required this.address,
    required this.apiClient,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder<List<TenantProfile>>(
      future: apiClient.getAddressTenants(address.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final tenants = snapshot.data ?? [];
        if (tenants.isEmpty) {
          return Text(
            l10n.addressNoTenants,
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.addressTenantsSection,
              style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ...tenants.map((t) => TenantTile(tenant: t)),
          ],
        );
      },
    );
  }
}

