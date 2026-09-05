import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/settings/settings_row.dart';
import 'package:papyrus/widgets/shared/app_motion_control.dart';

void main() {
  final themes = {'light': AppTheme.light, 'dark': AppTheme.dark, 'eink': AppTheme.eink};

  ToggleableStateMixin toggleState(WidgetTester tester) => tester.allStates.whereType<ToggleableStateMixin>().single;

  testWidgets('chip motion refreshes across theme switches and retains keyboard focus', (tester) async {
    final theme = ValueNotifier(AppTheme.light);
    final selected = ValueNotifier(false);
    final focus = FocusNode();
    addTearDown(theme.dispose);
    addTearDown(selected.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<ThemeData>(
        valueListenable: theme,
        builder: (_, value, _) => MaterialApp(
          theme: value,
          themeAnimationDuration: Duration.zero,
          home: Scaffold(
            body: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: selected,
                builder: (context, value, _) => AppMotionControl(
                  value: null,
                  focusNode: focus,
                  builder: (focusNode) => FilterChip(
                    focusNode: focusNode,
                    label: const Text('Option'),
                    selected: value,
                    onSelected: (value) => selected.value = value,
                    chipAnimationStyle: appChipAnimationStyle(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    theme.value = AppTheme.eink;
    await tester.pump();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(selected.value, isTrue);
    final selectedWidth = tester.getSize(find.byType(RawChip)).width;
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(RawChip)).width, selectedWidth);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.pump();
    expect(selected.value, isFalse);
    expect(focus.hasFocus, isTrue);
    final deselectedWidth = tester.getSize(find.byType(RawChip)).width;
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(RawChip)).width, deselectedWidth);
    expect(deselectedWidth, lessThan(selectedWidth));
    theme.value = AppTheme.dark;
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final animatedWidth = tester.getSize(find.byType(RawChip)).width;
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(RawChip)).width, greaterThan(animatedWidth));
  });

  for (final theme in themes.entries) {
    for (final kind in ['checkbox', 'switch', 'checkbox tile', 'switch tile', 'settings switch']) {
      testWidgets('${theme.key} $kind paints changed values with the expected motion', (tester) async {
        final value = ValueNotifier(false);
        addTearDown(value.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.value,
            home: Scaffold(
              body: Center(
                child: ValueListenableBuilder<bool>(
                  valueListenable: value,
                  builder: (context, selected, _) {
                    if (kind == 'settings switch') {
                      return SettingsToggleRow(
                        label: 'Setting',
                        value: selected,
                        onChanged: (changed) => value.value = changed,
                      );
                    }
                    return AppMotionControl(
                      value: selected,
                      builder: (focusNode) {
                        void changed(bool? changed) => value.value = changed!;
                        return switch (kind) {
                          'checkbox' => Checkbox(value: selected, onChanged: changed, focusNode: focusNode),
                          'switch' => Switch(value: selected, onChanged: changed, focusNode: focusNode),
                          'checkbox tile' => CheckboxListTile(
                            value: selected,
                            onChanged: changed,
                            focusNode: focusNode,
                            title: const Text('Setting'),
                          ),
                          _ => SwitchListTile(
                            value: selected,
                            onChanged: changed,
                            focusNode: focusNode,
                            title: const Text('Setting'),
                          ),
                        };
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(toggleState(tester).position.value, 0);
        final target = kind.contains('checkbox') ? find.byType(Checkbox) : find.byType(Switch);
        await tester.tap(target);
        await tester.pump();
        await tester.pump();
        expect(value.value, isTrue);
        if (theme.key == 'eink') {
          expect(toggleState(tester).position.value, 1);
          expect(toggleState(tester).positionController.isAnimating, isFalse);
        } else {
          await tester.pump(const Duration(milliseconds: 40));
          expect(toggleState(tester).position.value, inExclusiveRange(0, 1));
        }
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pump();
        await tester.pump();
        expect(value.value, isFalse);
        if (theme.key == 'eink') expect(toggleState(tester).position.value, 0);
        await tester.pumpAndSettle();
      });
    }
  }

  for (final tile in [false, true]) {
    testWidgets('eink ${tile ? 'tile' : 'checkbox'} preserves focus for repeated keyboard changes', (tester) async {
      final value = ValueNotifier(false);
      final focus = FocusNode();
      addTearDown(value.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.eink,
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: value,
              builder: (context, selected, _) => AppMotionControl(
                value: selected,
                focusNode: focus,
                builder: (focusNode) => tile
                    ? CheckboxListTile(
                        value: selected,
                        onChanged: (changed) => value.value = changed!,
                        focusNode: focusNode,
                        title: const Text('Setting'),
                      )
                    : Checkbox(value: selected, onChanged: (changed) => value.value = changed!, focusNode: focusNode),
              ),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      for (final expected in [true, false, true]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        await tester.pump();
        expect(value.value, expected);
        expect(toggleState(tester).position.value, expected ? 1 : 0);
        expect(focus.hasFocus, isTrue);
      }
    });
  }

  for (final theme in themes.entries) {
    for (final kind in ['choice', 'filter', 'action']) {
      testWidgets('${theme.key} $kind chip selection uses the expected animation style', (tester) async {
        final value = ValueNotifier(false);
        addTearDown(value.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.value,
            home: Scaffold(
              body: Center(
                child: ValueListenableBuilder<bool>(
                  valueListenable: value,
                  builder: (context, selected, _) {
                    final style = appChipAnimationStyle(context);
                    return AppMotionControl(
                      value: null,
                      builder: (focusNode) => switch (kind) {
                        'choice' => ChoiceChip(
                          focusNode: focusNode,
                          label: const Text('Option'),
                          selected: selected,
                          onSelected: (changed) => value.value = changed,
                          chipAnimationStyle: style,
                        ),
                        'filter' => FilterChip(
                          focusNode: focusNode,
                          label: const Text('Option'),
                          selected: selected,
                          onSelected: (changed) => value.value = changed,
                          chipAnimationStyle: style,
                        ),
                        _ => ActionChip(
                          focusNode: focusNode,
                          label: const Text('Option'),
                          avatar: selected ? const Icon(Icons.check) : null,
                          onPressed: () => value.value = !selected,
                          chipAnimationStyle: style,
                        ),
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Option'));
        await tester.pump();
        await tester.pump();
        expect(value.value, isTrue);
        final chip = tester.widget<RawChip>(find.byType(RawChip));
        if (theme.key == 'eink') {
          final style = chip.chipAnimationStyle!;
          for (final animation in [
            style.enableAnimation,
            style.selectAnimation,
            style.avatarDrawerAnimation,
            style.deleteDrawerAnimation,
          ]) {
            expect(animation!.duration, Duration.zero);
            expect(animation.reverseDuration, Duration.zero);
          }
          final immediateWidth = tester.getSize(find.byType(RawChip)).width;
          await tester.pumpAndSettle();
          expect(tester.getSize(find.byType(RawChip)).width, immediateWidth);
        } else {
          expect(chip.chipAnimationStyle, isNull);
          await tester.pumpAndSettle();
        }
      });
    }
  }
}
