import 'dart:ui' show SemanticsAction, SemanticsFlag, Tristate;

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
  const submissionError = 'The download client rejected this release.';
  const semanticLabel =
      'The Left Hand of Darkness EPUB. Nyaa. EPUB, RETAIL. 1.5 MB. 12 seeders. '
      'The download client rejected this release.';

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
    await tester.pumpWidget(
      buildList(releases: const [release, otherRelease], errorsByReleaseToken: const {'token-1': submissionError}),
    );

    final errorText = tester.widget<Text>(find.text(submissionError));

    expect(errorText.style?.fontSize, AppTheme.dark.textTheme.bodySmall?.fontSize);
    expect(errorText.style?.color, AppTheme.dark.colorScheme.error);
    expect(find.text(otherRelease.title), findsOneWidget);
    expect(find.text(submissionError), findsOneWidget);
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

  testWidgets('exposes one selected release row as an actionable semantic toggle', (tester) async {
    final semantics = tester.ensureSemantics();

    try {
      await tester.pumpWidget(
        buildList(selectedReleaseTokens: const {'token-1'}, errorsByReleaseToken: const {'token-1': submissionError}),
      );

      final releaseNodes = find.semantics.byLabel(semanticLabel).evaluate().toList();
      final releaseSemantics = tester.getSemantics(find.byKey(const ValueKey('remote-release-token-1')));

      expect(releaseNodes, hasLength(1));
      expect(releaseSemantics.label, semanticLabel);
      expect(releaseSemantics.flagsCollection.isButton, isTrue);
      expect(releaseSemantics.flagsCollection.isSelected, Tristate.isTrue);
      expect(releaseSemantics.hasFlag(SemanticsFlag.isSelected), isTrue);
      expect(releaseSemantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      final unlabeledInteractiveNodes = find.semantics
          .byPredicate(
            (node) =>
                node.label.isEmpty &&
                (node.getSemanticsData().hasAction(SemanticsAction.tap) ||
                    node.flagsCollection.isFocused != Tristate.none),
          )
          .evaluate();

      expect(unlabeledInteractiveNodes, isEmpty);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('semantic tap toggles the unselected release exactly once', (tester) async {
    final semantics = tester.ensureSemantics();
    final toggled = <String>[];

    try {
      await tester.pumpWidget(buildList(onToggleSelection: toggled.add));

      final releaseSemantics = tester.getSemantics(find.byKey(const ValueKey('remote-release-token-1')));

      expect(releaseSemantics.flagsCollection.isSelected, Tristate.isFalse);
      tester.semantics.tap(
        find.semantics.byLabel('The Left Hand of Darkness EPUB. Nyaa. EPUB, RETAIL. 1.5 MB. 12 seeders'),
      );

      expect(toggled, ['token-1']);
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
