import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/acquisition/acquisition_endpoint_editor.dart';

void main() {
  testWidgets('uses a content-driven draggable bottom sheet on narrow windows', (tester) async {
    await _setWindowSize(tester, const Size(390, 844));
    await tester.pumpWidget(_EditorLauncher());

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('acquisition-endpoint-sheet'));
    expect(sheet, findsOneWidget);
    expect(find.byKey(const Key('acquisition-endpoint-dialog')), findsNothing);
    expect(
      find.descendant(
        of: sheet,
        matching: find.byWidgetPredicate((widget) => widget is FractionallySizedBox && widget.heightFactor == .92),
      ),
      findsNothing,
    );
    expect(find.ancestor(of: sheet, matching: find.byType(AnimatedPadding)), findsOneWidget);
    final bottomSheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(bottomSheet.enableDrag, isTrue);
    expect(bottomSheet.showDragHandle, isTrue);
    expect(find.ancestor(of: sheet, matching: find.byType(SafeArea)), findsOneWidget);
  });

  testWidgets('short editor hugs its content on wide windows', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    await tester.pumpWidget(_EditorLauncher());

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('acquisition-endpoint-sheet'));
    expect(sheet, findsOneWidget);
    expect(find.byKey(const Key('acquisition-endpoint-dialog')), findsNothing);
    expect(
      find.descendant(
        of: sheet,
        matching: find.byWidgetPredicate((widget) => widget is FractionallySizedBox && widget.heightFactor == .92),
      ),
      findsNothing,
    );
    expect(tester.getSize(sheet).height, lessThan(700));
    expect(find.ancestor(of: sheet, matching: find.byType(SafeArea)), findsOneWidget);
  });

  testWidgets('idle sheet dismisses from the backdrop', (tester) async {
    await _expectIdleSheetDismisses(tester, _DismissAttempt.barrier);
  });

  testWidgets('idle sheet dismisses from system back', (tester) async {
    await _expectIdleSheetDismisses(tester, _DismissAttempt.back);
  });

  testWidgets('idle sheet dismisses from a downward drag', (tester) async {
    await _expectIdleSheetDismisses(tester, _DismissAttempt.drag);
  });

  testWidgets('credential-rich editor stays below the keyboard and scrolls to its footer', (tester) async {
    await _setWindowSize(tester, const Size(390, 844));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
    await tester.pumpWidget(_EditorLauncher(endpoint: _downloadClient));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final keyboardInset = tester.view.viewInsets.bottom;
    final availableHeight = 844 - keyboardInset;
    final bottomSheet = find.byType(BottomSheet);
    expect(tester.getSize(bottomSheet).height, lessThanOrEqualTo(keyboardInset + availableHeight * .92));
    expect(
      tester.getBottomLeft(find.byKey(const Key('acquisition-editor-footer'))).dy,
      lessThanOrEqualTo(availableHeight),
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    final verticalScrollable = find
        .byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down)
        .first;
    await tester.scrollUntilVisible(find.byKey(const Key('acquisition-password')), 200, scrollable: verticalScrollable);

    expect(find.byKey(const Key('acquisition-password')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-editor-footer')), findsOneWidget);
  });

  testWidgets('groups fields and shows credentials required by integration type', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    await tester.pumpWidget(_EditorLauncher());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Integration'), findsOneWidget);
    expect(find.text('Connection'), findsOneWidget);
    expect(find.byKey(const Key('acquisition-name')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-type')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-url')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-api-key')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-username')), findsNothing);
    expect(find.byKey(const Key('acquisition-password')), findsNothing);
    expect(
      find.byWidgetPredicate((widget) => widget is SizedBox && widget.height == Spacing.formFieldSpacing),
      findsAtLeastNWidgets(3),
    );

    await _chooseKind(tester, 'qBittorrent');

    expect(find.byKey(const Key('acquisition-api-key')), findsNothing);
    expect(find.byKey(const Key('acquisition-username')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-password')), findsOneWidget);

    await _chooseKind(tester, 'Transmission');

    expect(find.byKey(const Key('acquisition-username')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-password')), findsOneWidget);

    await _chooseKind(tester, 'Deluge');

    expect(find.byKey(const Key('acquisition-api-key')), findsNothing);
    expect(find.byKey(const Key('acquisition-username')), findsNothing);
    expect(find.byKey(const Key('acquisition-password')), findsOneWidget);
  });

  testWidgets('shows Enabled only when editing an integration', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    await tester.pumpWidget(_EditorLauncher());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SwitchListTile, 'Enabled'), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_EditorLauncher(endpoint: _endpoint));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SwitchListTile, 'Enabled'), findsOneWidget);
  });

  testWidgets('validates name and server URL inline', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    await tester.pumpWidget(_EditorLauncher());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('acquisition-save')));
    await tester.pump();

    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter a valid server URL'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('acquisition-name')), 'Prowlarr');
    for (final invalidUrl in ['prowlarr.local', 'https://', 'https://reader:secret@prowlarr.local']) {
      await tester.enterText(find.byKey(const Key('acquisition-url')), invalidUrl);
      await tester.tap(find.byKey(const Key('acquisition-save')));
      await tester.pump();

      expect(find.text('Enter a valid server URL'), findsOneWidget);
    }
  });

  testWidgets('toggles secret visibility', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    await tester.pumpWidget(_EditorLauncher());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: find.byKey(const Key('acquisition-api-key')), matching: find.byType(EditableText)),
          )
          .obscureText,
      isTrue,
    );

    await tester.tap(find.byTooltip('Show API key'));
    await tester.pump();

    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: find.byKey(const Key('acquisition-api-key')), matching: find.byType(EditableText)),
          )
          .obscureText,
      isFalse,
    );
    expect(find.byTooltip('Hide API key'), findsOneWidget);
  });

  testWidgets('keeps connection testing in the body and reports success', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    final completer = Completer<void>();
    await tester.pumpWidget(
      _EditorLauncher(onTest: ({required kind, required baseUrl, apiKey, username, password}) => completer.future),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _enterRequiredFields(tester);

    final testButton = find.byKey(const Key('acquisition-test-connection'));
    final footer = find.byKey(const Key('acquisition-editor-footer'));
    expect(find.descendant(of: footer, matching: testButton), findsNothing);

    await tester.tap(testButton);
    await tester.pump();

    expect(tester.widget<OutlinedButton>(testButton).onPressed, isNull);
    expect(tester.widget<FilledButton>(find.byKey(const Key('acquisition-save'))).onPressed, isNull);
    expect(tester.widget<TextFormField>(find.byKey(const Key('acquisition-name'))).enabled, isFalse);
    expect(
      tester
          .widget<DropdownButtonFormField<AcquisitionEndpointKind>>(find.byKey(const Key('acquisition-type')))
          .onChanged,
      isNull,
    );
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancel')).onPressed, isNull);
    expect(
      tester
          .widget<IconButton>(
            find.descendant(of: find.byKey(const Key('acquisition-api-key')), matching: find.byType(IconButton)),
          )
          .onPressed,
      isNull,
    );

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.text('Connection successful.'), findsOneWidget);
  });

  testWidgets('tests valid connection details without requiring a name', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    var testCalls = 0;
    await tester.pumpWidget(
      _EditorLauncher(
        onTest: ({required kind, required baseUrl, apiKey, username, password}) async {
          testCalls += 1;
        },
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('acquisition-url')), 'https://prowlarr.local');

    await tester.tap(find.byKey(const Key('acquisition-test-connection')));
    await tester.pumpAndSettle();

    expect(testCalls, 1);
    expect(find.text('Enter a name'), findsNothing);
    expect(find.text('Connection successful.'), findsOneWidget);
  });

  testWidgets('testing a corrected URL clears the error from a failed save', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    var testCalls = 0;
    await tester.pumpWidget(
      _EditorLauncher(
        onTest: ({required kind, required baseUrl, apiKey, username, password}) async {
          testCalls += 1;
        },
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('acquisition-name')), 'Prowlarr');
    await tester.enterText(find.byKey(const Key('acquisition-url')), 'https://');

    await tester.tap(find.byKey(const Key('acquisition-save')));
    await tester.pump();
    expect(find.text('Enter a valid server URL'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('acquisition-url')), 'https://prowlarr.local');
    await tester.tap(find.byKey(const Key('acquisition-test-connection')));
    await tester.pumpAndSettle();

    expect(testCalls, 1);
    expect(find.text('Enter a valid server URL'), findsNothing);
    expect(find.text('Connection successful.'), findsOneWidget);
  });

  testWidgets('reports connection errors locally', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    await tester.pumpWidget(
      _EditorLauncher(
        onTest: ({required kind, required baseUrl, apiKey, username, password}) =>
            Future<void>.error(const AuthApiException(statusCode: 502, message: 'Prowlarr connection test failed')),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _enterRequiredFields(tester);

    await tester.tap(find.byKey(const Key('acquisition-test-connection')));
    await tester.pumpAndSettle();

    expect(find.text('Prowlarr connection test failed'), findsOneWidget);
  });

  testWidgets('failed save restores idle drag and handle behavior', (tester) async {
    final saveCompleter = Completer<void>();
    await _setWindowSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      _EditorLauncher(
        onSave: ({required name, required kind, required baseUrl, required enabled, apiKey, username, password}) =>
            saveCompleter.future,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _enterRequiredFields(tester);

    await tester.tap(find.byKey(const Key('acquisition-save')));
    await tester.pump();

    var bottomSheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(bottomSheet.enableDrag, isFalse);
    expect(bottomSheet.showDragHandle, isFalse);

    saveCompleter.completeError(const AuthApiException(statusCode: 502, message: 'Could not save integration'));
    await tester.pumpAndSettle();

    bottomSheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(bottomSheet.enableDrag, isTrue);
    expect(bottomSheet.showDragHandle, isTrue);

    await tester.drag(find.byType(BottomSheet), const Offset(0, 700));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('acquisition-endpoint-sheet')), findsNothing);
  });

  testWidgets('successful save result cannot be stolen by an immediate idle dismissal', (tester) async {
    final saveCompleter = Completer<void>();
    bool? result;
    await _setWindowSize(tester, const Size(390, 844));
    await tester.pumpWidget(_SaveRaceLauncher(saveCompleter: saveCompleter, onResult: (value) => result = value));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _enterRequiredFields(tester);

    await tester.tap(find.byKey(const Key('acquisition-save')));
    await tester.pump();
    expect(result, isNull);

    saveCompleter.complete();
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.byType(AcquisitionEndpointEditor), findsNothing);
  });

  testWidgets('footer contains only Cancel and Save actions', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    await tester.pumpWidget(_EditorLauncher());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final footer = find.byKey(const Key('acquisition-editor-footer'));
    expect(find.descendant(of: footer, matching: find.byType(TextButton)), findsOneWidget);
    expect(find.descendant(of: footer, matching: find.byType(FilledButton)), findsOneWidget);
    expect(find.descendant(of: footer, matching: find.byType(OutlinedButton)), findsNothing);
    expect(find.descendant(of: footer, matching: find.text('Cancel')), findsOneWidget);
    expect(find.descendant(of: footer, matching: find.text('Save')), findsOneWidget);
  });

  testWidgets('blank credentials remain null when editing', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    String? savedApiKey = 'not-called';
    String? savedUsername = 'not-called';
    String? savedPassword = 'not-called';
    await tester.pumpWidget(
      _EditorLauncher(
        endpoint: _endpoint,
        onSave: ({required name, required kind, required baseUrl, required enabled, apiKey, username, password}) async {
          savedApiKey = apiKey;
          savedUsername = username;
          savedPassword = password;
        },
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('acquisition-save')));
    await tester.pumpAndSettle();

    expect(savedApiKey, isNull);
    expect(savedUsername, isNull);
    expect(savedPassword, isNull);
  });

  testWidgets('blank username and password remain null when editing', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    String? savedUsername = 'not-called';
    String? savedPassword = 'not-called';
    await tester.pumpWidget(
      _EditorLauncher(
        endpoint: _downloadClient,
        onSave: ({required name, required kind, required baseUrl, required enabled, apiKey, username, password}) async {
          savedUsername = username;
          savedPassword = password;
        },
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('acquisition-username')), findsOneWidget);
    expect(find.byKey(const Key('acquisition-password')), findsOneWidget);

    await tester.tap(find.byKey(const Key('acquisition-save')));
    await tester.pumpAndSettle();

    expect(savedUsername, isNull);
    expect(savedPassword, isNull);
  });

  testWidgets('pending save blocks sheet barrier dismissal', (tester) async {
    await _expectPendingSaveBlocksDismissal(tester, _DismissAttempt.barrier);
  });

  testWidgets('pending save blocks system back dismissal', (tester) async {
    await _expectPendingSaveBlocksDismissal(tester, _DismissAttempt.back);
  });

  testWidgets('pending save blocks sheet drag dismissal', (tester) async {
    await _expectPendingSaveBlocksDismissal(tester, _DismissAttempt.drag);
  });
}

class _EditorLauncher extends StatelessWidget {
  const _EditorLauncher({this.endpoint, this.onTest, this.onSave});

  final AcquisitionEndpoint? endpoint;
  final AcquisitionEndpointTestCallback? onTest;
  final AcquisitionEndpointSaveCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () {
                showAcquisitionEndpointEditor(
                  context: context,
                  endpoint: endpoint,
                  endpointKinds: AcquisitionEndpointKind.values,
                  initialKind: AcquisitionEndpointKind.prowlarr,
                  onTest: onTest ?? ({required kind, required baseUrl, apiKey, username, password}) async {},
                  onSave:
                      onSave ??
                      ({
                        required name,
                        required kind,
                        required baseUrl,
                        required enabled,
                        apiKey,
                        username,
                        password,
                      }) async {},
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveRaceLauncher extends StatelessWidget {
  const _SaveRaceLauncher({required this.saveCompleter, required this.onResult});

  final Completer<void> saveCompleter;
  final ValueChanged<bool?> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                late BuildContext editorContext;
                var wasBusy = false;
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  isDismissible: false,
                  enableDrag: false,
                  builder: (context) {
                    editorContext = context;

                    return AcquisitionEndpointEditor(
                      endpointKinds: AcquisitionEndpointKind.values,
                      initialKind: AcquisitionEndpointKind.prowlarr,
                      onTest: ({required kind, required baseUrl, apiKey, username, password}) async {},
                      onSave:
                          ({
                            required name,
                            required kind,
                            required baseUrl,
                            required enabled,
                            apiKey,
                            username,
                            password,
                          }) => saveCompleter.future,
                      onBusyChanged: (busy) {
                        if (busy) {
                          wasBusy = true;
                        } else if (wasBusy && Navigator.canPop(editorContext)) {
                          Navigator.pop(editorContext, false);
                        }
                      },
                    );
                  },
                );

                onResult(result);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _setWindowSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<void> _chooseKind(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('acquisition-type')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _enterRequiredFields(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('acquisition-name')), 'Prowlarr');
  await tester.enterText(find.byKey(const Key('acquisition-url')), 'https://prowlarr.local');
}

Future<void> _expectIdleSheetDismisses(WidgetTester tester, _DismissAttempt attempt) async {
  await _setWindowSize(tester, const Size(390, 844));
  await tester.pumpWidget(_EditorLauncher());
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  switch (attempt) {
    case _DismissAttempt.barrier:
      await tester.tapAt(const Offset(4, 4));
    case _DismissAttempt.back:
      await tester.binding.handlePopRoute();
    case _DismissAttempt.drag:
      await tester.drag(find.byType(BottomSheet), const Offset(0, 700));
  }
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('acquisition-endpoint-sheet')), findsNothing);
}

Future<void> _expectPendingSaveBlocksDismissal(WidgetTester tester, _DismissAttempt attempt) async {
  await _setWindowSize(tester, const Size(390, 844));
  final saveCompleter = Completer<void>();
  await tester.pumpWidget(
    _EditorLauncher(
      onSave: ({required name, required kind, required baseUrl, required enabled, apiKey, username, password}) =>
          saveCompleter.future,
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await _enterRequiredFields(tester);

  await tester.tap(find.byKey(const Key('acquisition-save')));
  await tester.pump();

  expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancel')).onPressed, isNull);
  final bottomSheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
  expect(bottomSheet.enableDrag, isFalse);
  expect(bottomSheet.showDragHandle, isFalse);

  switch (attempt) {
    case _DismissAttempt.barrier:
      await tester.tapAt(const Offset(4, 4));
    case _DismissAttempt.back:
      await tester.binding.handlePopRoute();
    case _DismissAttempt.drag:
      await tester.drag(find.byType(BottomSheet), const Offset(0, 700));
  }
  await tester.pump(const Duration(milliseconds: 500));

  expect(find.byKey(const Key('acquisition-endpoint-sheet')), findsOneWidget);

  saveCompleter.complete();
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('acquisition-endpoint-sheet')), findsNothing);
}

enum _DismissAttempt { barrier, back, drag }

final _endpoint = AcquisitionEndpoint(
  id: 'prowlarr-1',
  name: 'Prowlarr',
  kind: AcquisitionEndpointKind.prowlarr,
  baseUrl: Uri.parse('https://prowlarr.local'),
  enabled: true,
);

final _downloadClient = AcquisitionEndpoint(
  id: 'qbittorrent-1',
  name: 'qBittorrent',
  kind: AcquisitionEndpointKind.qbittorrent,
  baseUrl: Uri.parse('https://qbittorrent.local'),
  enabled: true,
);
