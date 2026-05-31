import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/address.dart';
import '../../../core/models/housing.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../l10n/app_localizations.dart';
import 'admin_invite_view_model.dart';

class AdminInviteScreen extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;

  const AdminInviteScreen({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  @override
  State<AdminInviteScreen> createState() => _AdminInviteScreenState();
}

class _AdminInviteScreenState extends State<AdminInviteScreen> {
  late final AdminInviteViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AdminInviteViewModel(
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
          title: Text(l10n.inviteCreateTitle),
          leading: _viewModel.step == AdminInviteStep.addressPicker
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _viewModel.goBack,
                )
              : null,
        ),
        body: AdaptiveLayout(
          child: SafeArea(
            child: _viewModel.step == AdminInviteStep.addressPicker
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _buildStep(context, l10n),
                    ),
                  )
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: _buildStep(context, l10n),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, AppLocalizations l10n) {
    if (_viewModel.isLoading && _viewModel.step == AdminInviteStep.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return switch (_viewModel.step) {
      AdminInviteStep.loading => const Center(
          child: CircularProgressIndicator(),
        ),
      AdminInviteStep.housingPicker => _HousingPickerStep(
          housings: _viewModel.housings,
          hasError: _viewModel.hasError,
          l10n: l10n,
          onSelect: _viewModel.selectHousing,
        ),
      AdminInviteStep.addressPicker => _AddressPickerStep(
          housing: _viewModel.selectedHousing!,
          isLoading: _viewModel.isLoading,
          hasError: _viewModel.hasError,
          l10n: l10n,
          onSelect: _viewModel.selectAddress,
        ),
      AdminInviteStep.created => _CreatedStep(
          viewModel: _viewModel,
          l10n: l10n,
        ),
    };
  }
}

// ---- Housing picker ---------------------------------------------------------

class _HousingPickerStep extends StatelessWidget {
  final List<Housing> housings;
  final bool hasError;
  final AppLocalizations l10n;
  final ValueChanged<Housing> onSelect;

  const _HousingPickerStep({
    required this.housings,
    required this.hasError,
    required this.l10n,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.invitePickHousing,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        if (hasError)
          Text(
            l10n.errorLoadFailed,
            style: TextStyle(color: colors.error),
          )
        else
          ...housings.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HousingCard(housing: h, onTap: () => onSelect(h)),
            ),
          ),
      ],
    );
  }
}

class _HousingCard extends StatelessWidget {
  final Housing housing;
  final VoidCallback onTap;

  const _HousingCard({required this.housing, required this.onTap});

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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      housing.name,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      housing.city,
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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

// ---- Address picker ---------------------------------------------------------

class _AddressPickerStep extends StatefulWidget {
  final Housing housing;
  final bool isLoading;
  final bool hasError;
  final AppLocalizations l10n;
  final ValueChanged<Address> onSelect;

  const _AddressPickerStep({
    required this.housing,
    required this.isLoading,
    required this.hasError,
    required this.l10n,
    required this.onSelect,
  });

  @override
  State<_AddressPickerStep> createState() => _AddressPickerStepState();
}

class _AddressPickerStepState extends State<_AddressPickerStep> {
  final TextEditingController _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  List<Address> get _filtered {
    final q = _filter.text.toLowerCase();
    if (q.isEmpty) return widget.housing.addresses;
    return widget.housing.addresses.where((a) {
      return a.shortDisplayAddress.toLowerCase().contains(q) ||
          (a.customerApartmentIdentifier?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.l10n.invitePickAddress,
                style:
                    text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.housing.name,
                style:
                    text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _filter,
                builder: (context, _) => TextField(
                  controller: _filter,
                  decoration: InputDecoration(
                    hintText: widget.l10n.inviteFilterAddresses,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _filter.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _filter.clear()),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty && _filter.text.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.l10n.inviteNoAddressesFound,
                    style: text.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  itemCount: filtered.length + (widget.hasError ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filtered.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.l10n.errorGeneric,
                          style: TextStyle(color: colors.error, fontSize: 13),
                        ),
                      );
                    }
                    final a = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AddressCard(
                        address: a,
                        isLoading: widget.isLoading,
                        onTap: () => widget.onSelect(a),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final bool isLoading;
  final VoidCallback onTap;

  const _AddressCard({
    required this.address,
    required this.isLoading,
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
        onTap: isLoading ? null : onTap,
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
                      address.shortDisplayAddress,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (address.isOccupied)
                      Text(
                        'Besat', // Occupied indicator for staff context
                        style: text.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Created step -----------------------------------------------------------

class _CreatedStep extends StatelessWidget {
  final AdminInviteViewModel viewModel;
  final AppLocalizations l10n;

  const _CreatedStep({required this.viewModel, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final inv = viewModel.createdInvitation!;
    final link = viewModel.invitationLink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle_outline, size: 48, color: colors.primary),
        const SizedBox(height: 16),
        Text(
          l10n.inviteCreatedTitle,
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (inv.address != null) ...[
          const SizedBox(height: 4),
          Text(
            inv.address!.displayAddress,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 32),
        Text(
          l10n.inviteCreatedSubtitle,
          style: text.labelLarge,
        ),
        const SizedBox(height: 8),
        _LinkBox(link: link),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _copyLink(context, link, l10n),
          icon: const Icon(Icons.copy),
          label: Text(l10n.inviteCopyLink),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: viewModel.reset,
          child: Text(l10n.inviteCreateAnother),
        ),
      ],
    );
  }

  void _copyLink(
    BuildContext context,
    String link,
    AppLocalizations l10n,
  ) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.inviteLinkCopied)),
    );
  }
}

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
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }
}
