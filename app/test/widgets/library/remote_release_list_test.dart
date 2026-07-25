import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/themes/app_theme.dart';
import 'package:papyrus/widgets/library/remote_release_list.dart';

void main() {
  const release = TorrentRelease(
    title: 'The Left Hand of Darkness EPUB',
    releaseToken: 'token-1',
    protocol: 'torrent',
    indexer: 'Nyaa',
    formatHints: ['epub', 'retail'],
    sizeBytes: 1572864,
    seeders: 12,
  );

  Widget buildList({
    List<TorrentRelease> releases = const [release],
    Set<String> selectedReleaseTokens = const {},
    Map<String, String> errorsByReleaseToken = const {},
    ValueChanged<String>? onToggleSelection,
    double width = 360,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: RemoteReleaseList(
            releases: releases,
            selectedReleaseTokens: selectedReleaseTokens,
            errorsByReleaseToken: errorsByReleaseToken,
            onToggleSelection: onToggleSelection ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows release details across the full-width row', (tester) async {
    await tester.pumpWidget(buildList());

    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.text(release.title), findsOneWidget);
    expect(find.text('Nyaa · EPUB, RETAIL · 1.5 MB · 12 seeders'), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('uses the selected color scheme treatment', (tester) async {
    await tester.pumpWidget(buildList(selectedReleaseTokens: const {'token-1'}));

    final colorScheme = AppTheme.dark.colorScheme;

    expect(
      tester.widgetList<Material>(find.byType(Material)).map((material) => material.color),
      contains(colorScheme.primaryContainer.withValues(alpha: 0.35)),
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('shows an inline error only for the failed release', (tester) async {
    const otherRelease = TorrentRelease(
      title: 'A Wizard of Earthsea MOBI',
      releaseToken: 'token-2',
      protocol: 'torrent',
      indexer: 'BookBay',
    );
    const error = 'The download client rejected this release.';

    await tester.pumpWidget(
      buildList(releases: const [release, otherRelease], errorsByReleaseToken: const {'token-1': error}),
    );

    final errorText = tester.widget<Text>(find.text(error));

    expect(errorText.style?.fontSize, AppTheme.dark.textTheme.bodySmall?.fontSize);
    expect(errorText.style?.color, AppTheme.dark.colorScheme.error);
    expect(find.text(otherRelease.title), findsOneWidget);
    expect(find.text(error), findsOneWidget);
  });

  testWidgets('row tap toggles its release exactly once', (tester) async {
    final toggled = <String>[];

    await tester.pumpWidget(buildList(onToggleSelection: toggled.add));
    await tester.tap(find.text(release.title));

    expect(toggled, ['token-1']);
  });

  testWidgets('checkbox toggle changes its release exactly once', (tester) async {
    final toggled = <String>[];

    await tester.pumpWidget(buildList(onToggleSelection: toggled.add));
    await tester.tap(find.byType(Checkbox));

    expect(toggled, ['token-1']);
  });

  testWidgets('exposes title and selected state to semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    try {
      await tester.pumpWidget(buildList(selectedReleaseTokens: const {'token-1'}));

      final releaseSemantics = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == release.title,
      );
      final semanticsNode = tester.getSemantics(releaseSemantics);

      expect(semanticsNode.hasFlag(SemanticsFlag.isSelected), isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('long metadata and inline error fit a narrow width', (tester) async {
    const longRelease = TorrentRelease(
      title:
          'An exceptionally long release title that needs to stay within a compact mobile result row without overflowing',
      releaseToken: 'long-token',
      protocol: 'torrent',
      indexer: 'An unusually descriptive indexer name',
      formatHints: ['epub', 'retail', 'audiobook'],
      sizeBytes: 1073741824,
      seeders: 9999,
    );

    await tester.pumpWidget(
      buildList(
        releases: const [longRelease],
        errorsByReleaseToken: const {
          'long-token': 'The download client rejected this release after a detailed response.',
        },
        width: 240,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
