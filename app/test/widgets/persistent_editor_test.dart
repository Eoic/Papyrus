import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/data/data_store.dart';
import 'package:papyrus/widgets/book_details/note_dialog.dart';
import 'package:papyrus/widgets/shelves/add_shelf_sheet.dart';
import 'package:papyrus/widgets/shelves/move_to_shelf_sheet.dart';
import 'package:papyrus/widgets/topics/add_topic_sheet.dart';
import 'package:papyrus/widgets/topics/manage_topics_sheet.dart';
import 'package:provider/provider.dart';

import '../helpers/test_helpers.dart';

void main() {
  for (final kind in ['shelf', 'topic', 'memberships', 'topic memberships', 'note']) {
    for (final fails in [false, true]) {
      testWidgets('$kind waits for persistence and ${fails ? 'stays open on failure' : 'closes on success'}', (
        tester,
      ) async {
        final write = Completer<void>();
        var calls = 0;
        Future<void> save() {
          calls++;
          return write.future;
        }

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: DataStore(),
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return TextButton(
                      onPressed: () {
                        switch (kind) {
                          case 'shelf':
                            AddShelfSheet.show(context, onSave: (_, _, _, _) => save());
                          case 'topic':
                            AddTopicSheet.show(context, onSave: (_, _, _) => save());
                          case 'memberships':
                            MoveToShelfSheet.show(
                              context,
                              book: buildTestBook(id: 'book'),
                              onSave: (_) => save(),
                            );
                          case 'topic memberships':
                            ManageTopicsSheet.show(
                              context,
                              book: buildTestBook(id: 'book'),
                              onSave: (_) => save(),
                            );
                          case 'note':
                            NoteDialog.show(context, bookId: 'book', onSave: (_) => save());
                        }
                      },
                      child: const Text('Open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        if (kind == 'shelf' || kind == 'topic' || kind == 'note') {
          await tester.enterText(find.byType(TextFormField).first, 'Name');
        }
        if (kind == 'note') {
          await tester.enterText(find.byKey(const Key('note-content-field')), 'Content');
        }
        await tester.pump();
        final button = find.widgetWithText(
          FilledButton,
          kind == 'shelf'
              ? 'Create shelf'
              : kind == 'topic'
              ? 'Create topic'
              : 'Save',
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        expect(calls, 1);
        expect(button, findsOneWidget);
        expect(tester.widget<FilledButton>(button).onPressed, isNull);

        if (fails) {
          write.completeError(StateError('Disk write failed'));
        } else {
          write.complete();
        }
        await tester.pumpAndSettle();
        expect(button, fails ? findsOneWidget : findsNothing);
        if (fails) {
          expect(find.text('Could not save changes. Please try again.'), findsOneWidget);
          expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
        }
      });
    }
  }
}
