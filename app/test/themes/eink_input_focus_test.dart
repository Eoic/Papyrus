import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/themes/app_theme.dart';

Future<Uint8List> _pixels(WidgetTester tester, GlobalKey key) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }))!;
}

void main() {
  for (final inlineBorder in [false, true]) {
    testWidgets('e-ink input focus paints its final state immediately (inline border: $inlineBorder)', (tester) async {
      final key = GlobalKey();
      final focus = FocusNode();
      final controller = TextEditingController();
      addTearDown(focus.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.eink,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 320,
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    showCursor: false,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter title',
                      border: inlineBorder ? const OutlineInputBorder() : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final initialSize = tester.getSize(find.byType(TextField));
      final unfocused = await _pixels(tester, key);
      focus.requestFocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final focused = await _pixels(tester, key);
      expect(listEquals(unfocused, focused), isFalse, reason: 'Keyboard focus must remain visibly distinct');
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        listEquals(focused, await _pixels(tester, key)),
        isTrue,
        reason: 'Focus must not interpolate the border or label',
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(listEquals(focused, await _pixels(tester, key)), isTrue);
      expect(tester.getSize(find.byType(TextField)), initialSize);
      await tester.enterText(find.byType(TextField), 'Papyrus');
      controller.selection = const TextSelection(baseOffset: 1, extentOffset: 4);
      await tester.pump();
      focus.unfocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final blurred = await _pixels(tester, key);
      await tester.pump(const Duration(milliseconds: 250));
      expect(listEquals(blurred, await _pixels(tester, key)), isTrue, reason: 'Losing focus must also be instant');
      expect(controller.text, 'Papyrus');
      expect(controller.selection, const TextSelection(baseOffset: 1, extentOffset: 4));
    });
  }

  for (final dark in [false, true]) {
    testWidgets('normal input focus keeps its animation (dark: $dark)', (tester) async {
      final key = GlobalKey();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 320,
                  child: TextField(
                    focusNode: focus,
                    showCursor: false,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      focus.requestFocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final initial = await _pixels(tester, key);
      await tester.pump(const Duration(milliseconds: 80));
      expect(listEquals(initial, await _pixels(tester, key)), isFalse);
      await tester.pumpAndSettle();
    });
  }

  testWidgets('theme changes preserve a focused form field and its validation', (tester) async {
    final eink = ValueNotifier(false);
    final focus = FocusNode();
    final controller = TextEditingController(text: 'Papyrus');
    final form = GlobalKey<FormState>();
    addTearDown(eink.dispose);
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<bool>(
        valueListenable: eink,
        builder: (_, ink, _) => MaterialApp(
          theme: ink ? AppTheme.eink : AppTheme.light,
          themeAnimationDuration: Duration.zero,
          home: Scaffold(
            body: Form(
              key: form,
              child: TextFormField(
                controller: controller,
                focusNode: focus,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (text) => text!.isEmpty ? 'Required' : null,
              ),
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    controller.selection = const TextSelection(baseOffset: 1, extentOffset: 4);
    eink.value = true;
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(controller.text, 'Papyrus');
    expect(controller.selection, const TextSelection(baseOffset: 1, extentOffset: 4));
    expect(form.currentState!.validate(), isTrue);
    controller.clear();
    expect(form.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
    eink.value = false;
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(find.text('Required'), findsOneWidget);
  });
}
