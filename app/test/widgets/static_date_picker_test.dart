import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/shared/app_date_picker.dart';
import 'package:papyrus/widgets/shared/app_drawer.dart';

void main() {
  testWidgets('e-ink calendar changes months and years instantly and saves a date', (tester) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.eink,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAppDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 9, 5),
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2028, 12, 31),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byTooltip('Next month'));
    await tester.pump();
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    await tester.tap(find.text('October 2026'));
    await tester.pump();
    expect(find.byType(YearPicker), findsOneWidget);
    await tester.tap(find.text('2027'));
    await tester.pump();
    expect(find.byType(YearPicker), findsNothing);
    expect(find.text('October 2027'), findsOneWidget);
    await tester.tap(find.text('15'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pump();
    expect(result, DateTime(2027, 10, 15));
  });

  testWidgets('e-ink range selection spans months and cancel preserves the original', (tester) async {
    DateTimeRange? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.eink,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAppDateRangePicker(
                  context: context,
                  initialDateRange: DateTimeRange(start: DateTime(2026, 9, 5), end: DateTime(2026, 9, 10)),
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2027),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('28'));
    await tester.pump();
    await tester.tap(find.byTooltip('Next month'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pump();
    expect(result, DateTimeRange(start: DateTime(2026, 9, 28), end: DateTime(2026, 10, 3)));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('20'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(result, isNull);
  });

  testWidgets('e-ink drawer opens and dismisses instantly at its regular width', (tester) async {
    final scaffold = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.eink,
        home: Scaffold(
          key: scaffold,
          drawer: const Drawer(child: Text('Sections')),
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () => openAppDrawer(context, scaffold.currentState), child: const Text('Open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    final drawer = find.byType(Drawer);
    expect(tester.getTopLeft(drawer).dx, 0);
    expect(tester.getSize(drawer).width, 304);
    await tester.tapAt(const Offset(700, 300));
    await tester.pump();
    await tester.pump();
    expect(find.text('Sections'), findsNothing);
  });

  testWidgets('e-ink typed dates validate and survive switching back to calendar', (tester) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.eink,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAppDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 9, 5),
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2027),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'invalid');
    await tester.tap(find.text('OK'));
    await tester.pump();
    expect(find.byType(InputDatePickerFormField), findsOneWidget);
    expect(result, isNull);
    await tester.enterText(find.byType(TextField), '10/20/2026');
    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pump();
    expect(find.text('October 2026'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pump();
    expect(result, DateTime(2026, 10, 20));
  });
}
