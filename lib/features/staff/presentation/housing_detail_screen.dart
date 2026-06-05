import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/address.dart';
import '../../../core/models/housing.dart';
import '../../../core/models/invitation.dart';
import '../../../core/models/issue.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../l10n/app_localizations.dart';
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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
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
              _LinkBox(link: link),
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

  const _UnitsTab({required this.sorted, required this.viewModel});

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

  const _AddressRow({
    required this.address,
    required this.status,
    required this.invitation,
    required this.isCancelling,
    required this.isCreating,
    required this.onInvite,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                _AddressStatusChip(status: status, l10n: l10n),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _AddressAction(
            status: status,
            invitation: invitation,
            isCancelling: isCancelling,
            isCreating: isCreating,
            onInvite: onInvite,
            onCancel: onCancel,
            l10n: l10n,
          ),
        ],
      ),
    );
  }
}

class _AddressStatusChip extends StatelessWidget {
  final AddressStatus status;
  final AppLocalizations l10n;

  const _AddressStatusChip({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, bg, fg) = switch (status) {
      AddressStatus.occupied => (
          l10n.addressStatusOccupied,
          colors.secondaryContainer,
          colors.onSecondaryContainer,
        ),
      AddressStatus.invitationPending => (
          l10n.addressStatusInvitationPending,
          colors.tertiaryContainer,
          colors.onTertiaryContainer,
        ),
      AddressStatus.vacant => (
          l10n.addressStatusVacant,
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
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

// ---- Link box ---------------------------------------------------------------

class _LinkBox extends StatelessWidget {
  final String link;

  const _LinkBox({required this.link});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: SelectableText(
        link,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
