import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/acquisition/guarded_bottom_sheet_route.dart';
import 'package:papyrus/widgets/book/book_bookmarks.dart';
import 'package:papyrus/widgets/library/acquisition_confirmation_dialog.dart';
import 'package:papyrus/widgets/shared/app_date_picker.dart';
import 'package:papyrus/widgets/shelves/add_shelf_sheet.dart';
import 'package:papyrus/widgets/shelves/shelf_card.dart';

class _Routes extends NavigatorObserver {
  Route<dynamic>? latest;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => latest = route;
}

void main() {
  final shelf = Shelf(id: 'shelf', name: 'Books', createdAt: DateTime.utc(2026), updatedAt: DateTime.utc(2026));
  final themes = {'light': AppTheme.light, 'dark': AppTheme.dark, 'eink': AppTheme.eink};

  Future<void> desktop(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget card() => Center(
    child: SizedBox(
      width: 200,
      height: 240,
      child: ShelfCard(shelf: shelf, onMoreTap: () {}),
    ),
  );

  double opacity(WidgetTester tester) =>
      tester.renderObject<RenderAnimatedOpacity>(find.byType(AnimatedOpacity)).opacity.value;

  for (final entry in themes.entries) {
    testWidgets('${entry.key} shelf hover ${entry.key == 'eink' ? 'updates instantly' : 'keeps its fade'}', (
      tester,
    ) async {
      await desktop(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: entry.value,
          home: Scaffold(body: card()),
        ),
      );
      await tester.pumpAndSettle();
      expect(opacity(tester), 0);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(ShelfCard)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      if (entry.key == 'eink') {
        expect(opacity(tester), 1);
      } else {
        expect(opacity(tester), greaterThan(0));
        expect(opacity(tester), lessThan(1));
      }
      await mouse.removePointer();
      await tester.pumpAndSettle();
    });
  }

  testWidgets('switching to eink finishes an active implicit transition', (tester) async {
    await desktop(tester);
    final theme = ValueNotifier(AppTheme.light);
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<ThemeData>(
        valueListenable: theme,
        builder: (_, value, _) => MaterialApp(
          theme: value,
          themeAnimationDuration: Duration.zero,
          home: Scaffold(body: card()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(ShelfCard)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(opacity(tester), inExclusiveRange(0, 1));
    theme.value = AppTheme.eink;
    await tester.pump();
    expect(opacity(tester), 1);
    await mouse.removePointer();
    await tester.pumpAndSettle();
  });

  for (final entry in themes.entries) {
    for (final overlay in ['dialog', 'sheet', 'guarded sheet', 'date', 'date range', 'popup']) {
      testWidgets('${entry.key} $overlay uses the motion policy on open and close', (tester) async {
        final routes = _Routes();
        final navigator = GlobalKey<NavigatorState>();
        final busy = ValueNotifier(false);
        addTearDown(busy.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            navigatorKey: navigator,
            navigatorObservers: [routes],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  if (overlay == 'popup') {
                    return BookBookmarks(
                      bookmarks: [
                        Bookmark(id: 'bookmark', bookId: 'book', position: 0.5, createdAt: DateTime.utc(2026)),
                      ],
                      bookTitle: 'Book',
                    );
                  }
                  return TextButton(
                    onPressed: () {
                      switch (overlay) {
                        case 'dialog':
                          showAcquisitionConfirmationDialog(
                            context: context,
                            title: 'Confirm',
                            message: 'Message',
                            actionLabel: 'Continue',
                          );
                        case 'sheet':
                          AddShelfSheet.show(context);
                        case 'guarded sheet':
                          showGuardedModalBottomSheet<void>(
                            context: context,
                            busy: busy,
                            shape: const RoundedRectangleBorder(),
                            builder: (_) => const SizedBox(height: 100, child: Text('Guarded')),
                          );
                        case 'date':
                          showAppDatePicker(
                            context: context,
                            initialDate: DateTime(2026, 9, 5),
                            firstDate: DateTime(2026),
                            lastDate: DateTime(2027),
                          );
                        case 'date range':
                          showAppDateRangePicker(
                            context: context,
                            initialDateRange: DateTimeRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
                            firstDate: DateTime(2026),
                            lastDate: DateTime(2027),
                          );
                      }
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(overlay == 'popup' ? find.byIcon(Icons.sort) : find.text('Open'));
        await tester.pump();
        await tester.pump();
        final route = routes.latest! as TransitionRoute<dynamic>;
        if (entry.key == 'eink') {
          expect(route.transitionDuration, Duration.zero);
          expect(route.animation!.value, 1);
        } else {
          expect(route.transitionDuration, greaterThan(Duration.zero));
          await tester.pump(const Duration(milliseconds: 50));
          expect(route.animation!.value, inExclusiveRange(0, 1));
          await tester.pumpAndSettle();
        }
        navigator.currentState!.pop();
        await tester.pump();
        await tester.pump();
        if (entry.key == 'eink') {
          expect(route.isActive, isFalse);
          expect(navigator.currentState!.canPop(), isFalse);
        } else {
          expect(route.animation!.status, AnimationStatus.reverse);
          await tester.pumpAndSettle();
          expect(navigator.currentState!.canPop(), isFalse);
        }
      });
    }
  }
}
