import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/themes/app_motion.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/shared/app_progress_indicator.dart';

void main() {
  test('e-ink keeps typography sizes and exposes strong selected contrast', () {
    final ink = AppTheme.eink;
    final normal = AppTheme.light;
    expect(ink.textTheme.bodyMedium?.fontSize, normal.textTheme.bodyMedium?.fontSize);
    expect(ink.textTheme.titleMedium?.fontSize, normal.textTheme.titleMedium?.fontSize);
    expect(ink.colorScheme.primaryContainer, Colors.black);
    expect(ink.colorScheme.onPrimaryContainer, Colors.white);
    expect(ink.colorScheme.outline, Colors.black);
    expect(ink.splashFactory, NoSplash.splashFactory);
    expect(ink.filledButtonTheme.style?.animationDuration, Duration.zero);
    expect(
      ink.pageTransitionsTheme.builders.values.every((builder) => builder.transitionDuration == Duration.zero),
      isTrue,
    );
  });

  testWidgets('theme motion scope preserves sizing and honors system reduced motion', (tester) async {
    final disabled = ValueNotifier(false);
    addTearDown(disabled.dispose);
    final readings = <(bool, Size, TextScaler)>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ValueListenableBuilder<bool>(
          valueListenable: disabled,
          builder: (_, value, _) => MediaQuery(
            data: const MediaQueryData(
              size: Size(1200, 800),
              textScaler: TextScaler.linear(1.3),
              disableAnimations: true,
            ),
            child: AppMotionScope(
              reduceAnimations: value,
              child: Builder(
                builder: (context) {
                  readings.add((
                    AppMotion.disabled(context),
                    MediaQuery.sizeOf(context),
                    MediaQuery.textScalerOf(context),
                  ));
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(readings.last, (true, const Size(1200, 800), const TextScaler.linear(1.3)));
    disabled.value = true;
    await tester.pump();
    expect(readings.last.$1, isTrue);
  });

  testWidgets('e-ink loading indicators stay static and still report actual progress', (tester) async {
    final progress = ValueNotifier<double?>(null);
    addTearDown(progress.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.eink,
        home: Scaffold(
          body: ValueListenableBuilder<double?>(
            valueListenable: progress,
            builder: (_, value, _) => Column(
              children: [
                AppCircularProgressIndicator(value: value),
                AppLinearProgressIndicator(value: value),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final circle = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
    final line = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(circle.value, isNull);
    expect(line.value, isNull);
    expect(circle.controller?.value, 0.5);
    expect(line.controller?.value, 0.5);
    await tester.pump(const Duration(seconds: 2));
    expect(circle.controller?.value, 0.5);
    expect(tester.binding.hasScheduledFrame, isFalse);
    progress.value = 0.75;
    await tester.pump();
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.75);
    expect(tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).value, 0.75);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('normal-theme indeterminate loaders continue animating', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AppCircularProgressIndicator()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
