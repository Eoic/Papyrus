import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/providers/preferences_provider.dart';
import 'package:papyrus/providers/sidebar_provider.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/shell/adaptive_app_shell.dart';
import 'package:papyrus/widgets/shell/desktop_sidebar.dart';
import 'package:papyrus/widgets/shell/mobile_bottom_nav.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final width in [390.0, 850.0, 1440.0]) {
    testWidgets('e-ink preserves navigation layout at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final prefs = PreferencesProvider(await SharedPreferences.getInstance());
      final router = GoRouter(
        initialLocation: '/library/books',
        routes: [
          ShellRoute(
            builder: (_, _, child) => AdaptiveAppShell(child: child),
            routes: [GoRoute(path: '/library/books', builder: (_, _) => const Text('Library content'))],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: prefs),
            ChangeNotifierProvider(create: (_) => DataStore()),
            ChangeNotifierProvider(create: (_) => SidebarProvider()),
          ],
          child: Consumer<PreferencesProvider>(
            builder: (_, preferences, _) => MaterialApp.router(
              theme: preferences.isEinkMode ? AppTheme.eink : AppTheme.light,
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final desktop = find.byType(DesktopSidebar).evaluate().isNotEmpty;
      final mobile = find.byType(MobileBottomNav).evaluate().isNotEmpty;
      expect(desktop, width >= 840);
      final contentBounds = tester.getRect(find.text('Library content'));
      prefs.themeModePref = 'eink';
      await tester.pumpAndSettle();
      expect(find.byType(DesktopSidebar), desktop ? findsOneWidget : findsNothing);
      expect(find.byType(MobileBottomNav), mobile ? findsOneWidget : findsNothing);
      expect(tester.getRect(find.text('Library content')).left, contentBounds.left);
      expect(router.routeInformationProvider.value.uri.path, '/library/books');
      prefs.themeModePref = 'light';
      await tester.pumpAndSettle();
      expect(find.byType(DesktopSidebar), desktop ? findsOneWidget : findsNothing);
      expect(find.byType(MobileBottomNav), mobile ? findsOneWidget : findsNothing);
    });
  }
}
