import 'package:flutter/material.dart';

import '../../../core/models/tenant_profile.dart';
import '../../../l10n/app_localizations.dart';
import 'housing_detail_view_model.dart';

/// A small coloured chip showing the occupancy status of an address.
class AddressStatusChip extends StatelessWidget {
  final AddressStatus status;
  final AppLocalizations l10n;

  const AddressStatusChip({
    super.key,
    required this.status,
    required this.l10n,
  });

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

/// Displays a single tenant's avatar, name, email, and optional phone number.
class TenantTile extends StatelessWidget {
  final TenantProfile tenant;

  const TenantTile({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.secondaryContainer,
            child: Text(
              _initials(tenant.name ?? tenant.email),
              style: text.labelSmall?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tenant.name != null)
                  Text(
                    tenant.name!,
                    style:
                        text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                Text(
                  tenant.email,
                  style:
                      text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
                if (tenant.phoneNumber != null)
                  Text(
                    tenant.phoneNumber!,
                    style: text.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }
}

/// A monospace box that displays an invitation deep-link URL.
class LinkBox extends StatelessWidget {
  final String link;

  const LinkBox({super.key, required this.link});

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
