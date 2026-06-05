import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/theme_mode_service.dart';

const double _kRailBreakpoint = 640.0;
const double _kRailWidth = 72.0;

/// Adaptive navigation shell.
///
/// Renders a [NavigationBar] at the bottom on screens narrower than 640 px,
/// and a custom side rail on wider screens. Logout and theme controls live in
/// the [AppBar] on mobile and in the rail footer on desktop.
///
/// Pass [floatingActionButton] for destinations that need a primary action.
class AppShell extends StatelessWidget {
  /// Keys used by integration tests to locate shell navigation widgets.
  static const Key navRailKey = Key('app-shell-nav-rail');
  static const Key navBarKey  = Key('app-shell-nav-bar');

  const AppShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    required this.authService,
    required this.themeModeService,
    this.floatingActionButton,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;
  final AuthService authService;
  final ThemeModeService themeModeService;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= _kRailBreakpoint
              ? _DesktopShell(shell: this)
              : _MobileShell(shell: this),
    );
  }
}

// ---- Mobile layout ----------------------------------------------------------

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.shell});

  final AppShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          _ThemeToggleButton(
            themeModeService: shell.themeModeService,
            l10n: l10n,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logoutTooltip,
            onPressed: shell.authService.logout,
          ),
        ],
      ),
      body: shell.child,
      floatingActionButton: shell.floatingActionButton,
      bottomNavigationBar: shell.destinations.length > 1
          ? NavigationBar(
              key: AppShell.navBarKey,
              selectedIndex: shell.selectedIndex,
              onDestinationSelected: shell.onDestinationSelected,
              destinations: shell.destinations,
            )
          : null,
    );
  }
}

// ---- Desktop layout ---------------------------------------------------------

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.shell});

  final AppShell shell;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      floatingActionButton: shell.floatingActionButton,
      body: Row(
        children: [
          _AppRail(key: AppShell.navRailKey, shell: shell),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colors.outlineVariant,
          ),
          Expanded(child: shell.child),
        ],
      ),
    );
  }
}

// ---- Custom side rail -------------------------------------------------------

/// Custom sidebar rail.
///
/// Built from scratch (rather than [NavigationRail]) to allow placing
/// logout and theme controls in the footer regardless of destination count.
class _AppRail extends StatelessWidget {
  const _AppRail({super.key, required this.shell});

  final AppShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: _kRailWidth,
      color: colors.surface,
      child: Column(
        children: [
          // Leading: app name
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
            child: Text(
              l10n.appName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 8),
          // Destinations
          ...List.generate(shell.destinations.length, (index) {
            final dest = shell.destinations[index];
            final selected = index == shell.selectedIndex;
            return _RailTile(
              icon: selected
                  ? (dest.selectedIcon ?? dest.icon)
                  : dest.icon,
              label: dest.label,
              selected: selected,
              onTap: () => shell.onDestinationSelected(index),
            );
          }),
          const Spacer(),
          // Footer controls
          _ThemeToggleButton(
            themeModeService: shell.themeModeService,
            l10n: l10n,
            size: 20,
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: l10n.logoutTooltip,
            onPressed: shell.authService.logout,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? colors.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: selected
                      ? colors.onSecondaryContainer
                      : colors.onSurfaceVariant,
                  size: 24,
                ),
                child: icon,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: selected
                    ? colors.onSurface
                    : colors.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Shared controls --------------------------------------------------------

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({
    required this.themeModeService,
    required this.l10n,
    this.size,
  });

  final ThemeModeService themeModeService;
  final AppLocalizations l10n;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeModeService,
      builder: (context, _) => IconButton(
        icon: Icon(
          themeModeService.isDark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
          size: size,
        ),
        tooltip: themeModeService.isDark
            ? l10n.themeToggleToLight
            : l10n.themeToggleToDark,
        onPressed: themeModeService.toggle,
      ),
    );
  }
}
