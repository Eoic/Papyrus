import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/acquisition/acquisition_settings_section.dart';
import 'package:papyrus/widgets/settings/settings_row.dart';
import 'package:papyrus/widgets/settings/settings_section.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child, {double width = 600}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  testWidgets('empty section uses one SettingsCard and no literal Card', (tester) async {
    await pump(tester, const AcquisitionSettingsSection(title: 'Sources', emptyMessage: 'No sources configured'));

    expect(find.byType(AcquisitionSettingsSection), findsOneWidget);
    expect(find.byType(SettingsCard), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.text('No sources configured'), findsOneWidget);
  });

  testWidgets('section Add invokes its callback', (tester) async {
    var addCalls = 0;

    await pump(
      tester,
      AcquisitionSettingsSection(title: 'Sources', emptyMessage: 'No sources configured', onAdd: () => addCalls += 1),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Add'));
    await tester.pump();

    expect(addCalls, 1);
  });

  testWidgets('title is a header and Add exposes one contextual button node', (tester) async {
    await pump(tester, AcquisitionSettingsSection(title: 'Sources', onAdd: () {}));

    final header = tester.getSemantics(find.text('Sources'));
    final add = tester.getSemantics(find.bySemanticsLabel('Add to Sources'));

    expect(header.flagsCollection.isHeader, isTrue);
    expect(find.bySemanticsLabel('Add to Sources'), findsOneWidget);
    expect(add.flagsCollection.isButton, isTrue);
    expect(add.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  });

  testWidgets('populated children take priority and null Add stays hidden', (tester) async {
    await pump(
      tester,
      const AcquisitionSettingsSection(
        title: 'Sources',
        emptyMessage: 'No sources configured',
        children: [Text('Prowlarr')],
      ),
    );

    expect(find.text('Prowlarr'), findsOneWidget);
    expect(find.text('No sources configured'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Add'), findsNothing);
    expect(find.bySemanticsLabel('Add to Sources'), findsNothing);
  });

  testWidgets('SettingsRow leading uses its slot and falls back to a chevron', (tester) async {
    await pump(
      tester,
      SettingsRow(
        label: 'Prowlarr',
        leading: const Icon(Icons.rss_feed, key: Key('leading')),
        onTap: () {},
      ),
    );

    expect(find.byKey(const Key('leading')), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(tester.getCenter(find.byKey(const Key('leading'))).dx, lessThan(tester.getCenter(find.text('Prowlarr')).dx));
  });

  testWidgets('SettingsRow custom trailing wins while navigation retains its value subtitle', (tester) async {
    await pump(
      tester,
      SettingsRow(
        label: 'Prowlarr',
        value: 'Enabled',
        onTap: () {},
        trailing: const Icon(Icons.more_vert, key: Key('custom-trailing')),
      ),
    );

    expect(find.text('Enabled'), findsOneWidget);
    expect(find.byKey(const Key('custom-trailing')), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(
      tester.getCenter(find.text('Prowlarr')).dx,
      lessThan(tester.getCenter(find.byKey(const Key('custom-trailing'))).dx),
    );
  });

  testWidgets('value-only SettingsRow shows one value aligned to the right', (tester) async {
    await pump(tester, const SettingsRow(label: 'Server support', value: 'Available', showChevron: false));

    expect(find.text('Available'), findsOneWidget);
    expect(tester.getCenter(find.text('Server support')).dx, lessThan(tester.getCenter(find.text('Available')).dx));
    expect(tester.getCenter(find.text('Server support')).dy, tester.getCenter(find.text('Available')).dy);
  });

  testWidgets('SettingsRow meets the mobile target and grows for multiline content', (tester) async {
    await pump(tester, const SettingsRow(label: 'Short row', showChevron: false));

    expect(tester.getSize(find.byType(SettingsRow)).height, greaterThanOrEqualTo(TouchTargets.mobileRecommended));

    await pump(
      tester,
      const SettingsRow(label: 'A deliberately long settings label that wraps onto several lines', showChevron: false),
      width: 180,
    );

    expect(tester.getSize(find.byType(SettingsRow)).height, greaterThan(TouchTargets.mobileRecommended));
  });
}
