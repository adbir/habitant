import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beboer_app/core/services/auth_service.dart';
import 'package:beboer_app/core/services/theme_mode_service.dart';
import 'package:beboer_app/core/widgets/app_shell.dart';
import 'package:beboer_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Minimal fake — AppShell only calls authService.logout from icon buttons.
// ---------------------------------------------------------------------------
class _FakeAuthService extends Fake implements AuthService {
  @override
  Future<void> logout() async {}

  @override
  void addListener(VoidCallback l) {}
  @override
  void removeListener(VoidCallback l) {}
  @override
  void dispose() {}
}

// ---------------------------------------------------------------------------
// Test helper
// ---------------------------------------------------------------------------
Widget _buildShell({required double width, required double height}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SizedBox(
        width: width,
        height: height,
        child: AppShell(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Mine meldinger',
            ),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          authService: _FakeAuthService(),
          themeModeService: ThemeModeService(),
          child: const SizedBox.expand(),
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('AppShell adaptive layout', () {
    testWidgets('narrow (<640 px): shows AppBar, no rail', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildShell(width: 390, height: 844));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget,
          reason: 'mobile layout must show AppBar');
      expect(find.byKey(AppShell.navRailKey), findsNothing,
          reason: 'side rail must not appear on mobile');
    });

    testWidgets('wide (>=640 px): shows rail, no AppBar', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildShell(width: 1280, height: 800));
      await tester.pumpAndSettle();

      expect(find.byKey(AppShell.navRailKey), findsOneWidget,
          reason: 'desktop layout must show the side rail');
      expect(find.byType(AppBar), findsNothing,
          reason: 'AppBar must not appear on desktop');
    });

    testWidgets('single destination: NavigationBar absent on both breakpoints',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      for (final width in [390.0, 1280.0]) {
        tester.view.physicalSize = Size(width, 800);
        await tester.pumpWidget(_buildShell(width: width, height: 800));
        await tester.pumpAndSettle();

        expect(find.byKey(AppShell.navBarKey), findsNothing,
            reason:
                'NavigationBar is only shown when 2+ destinations exist '
                '(width=$width)');
      }
    });

    testWidgets('breakpoint boundary: 639 px mobile, 640 px desktop',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      tester.view.physicalSize = const Size(639, 800);
      await tester.pumpWidget(_buildShell(width: 639, height: 800));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byKey(AppShell.navRailKey), findsNothing);

      tester.view.physicalSize = const Size(640, 800);
      await tester.pumpWidget(_buildShell(width: 640, height: 800));
      await tester.pumpAndSettle();
      expect(find.byKey(AppShell.navRailKey), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });
  });
}
