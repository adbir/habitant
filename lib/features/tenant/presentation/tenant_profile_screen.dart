import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../l10n/app_localizations.dart';
import 'tenant_profile_view_model.dart';

class TenantProfileScreen extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;

  const TenantProfileScreen({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  @override
  State<TenantProfileScreen> createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends State<TenantProfileScreen> {
  late final TenantProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TenantProfileViewModel(
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
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => AdaptiveLayout(
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
              onPressed: _viewModel.load,
              child: Text(l10n.errorRetry),
            ),
          ],
        ),
      );
    }

    final profile = _viewModel.profile;
    if (profile == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionLabel(l10n.profileAccountSection),
        _InfoCard(children: [
          if (profile.name != null)
            _InfoRow(
              icon: Icons.person_outline,
              value: profile.name!,
            ),
          _InfoRow(icon: Icons.email_outlined, value: profile.email),
          if (profile.phoneNumber != null)
            _InfoRow(
              icon: Icons.phone_outlined,
              value: profile.phoneNumber!,
            ),
          if (profile.phoneNumberSecondary != null)
            _InfoRow(
              icon: Icons.phone_outlined,
              value: profile.phoneNumberSecondary!,
            ),
        ]),
        const SizedBox(height: 24),
        _SectionLabel(l10n.profileAddressSection),
        _addressCard(context, l10n),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => context.push('/tenant/claim-invitation'),
          icon: const Icon(Icons.link),
          label: Text(l10n.profileClaimInvitation),
        ),
      ],
    );
  }

  Widget _addressCard(BuildContext context, AppLocalizations l10n) {
    final housing = _viewModel.housing;
    final address = _viewModel.address;

    if (housing == null || address == null) {
      return _InfoCard(children: [
        _InfoRow(
          icon: Icons.home_outlined,
          value: l10n.profileNoAddress,
          muted: true,
        ),
      ]);
    }

    return _InfoCard(children: [
      _InfoRow(icon: Icons.apartment_outlined, value: housing.name),
      _InfoRow(
        icon: Icons.location_on_outlined,
        value: address.displayAddress,
      ),
    ]);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool muted;

  const _InfoRow({
    required this.icon,
    required this.value,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: muted ? colorScheme.outline : colorScheme.primary,
      ),
      title: Text(
        value,
        style: muted
            ? TextStyle(color: colorScheme.onSurfaceVariant)
            : null,
      ),
    );
  }
}
