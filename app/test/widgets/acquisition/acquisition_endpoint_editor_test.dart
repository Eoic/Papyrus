import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/auth/auth_api_client.dart';
import 'package:papyrus/themes/design_tokens.dart';
import 'package:papyrus/widgets/acquisition/acquisition_endpoint_editor.dart';

void main() {
  testWidgets('uses a keyboard-aware bottom sheet on narrow windows', (tester) async {
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
      findsOneWidget,
    );
    expect(find.descendant(of: sheet, matching: find.byType(AnimatedPadding)), findsOneWidget);
    expect(tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle, isTrue);
    expect(find.ancestor(of: sheet, matching: find.byType(SafeArea)), findsOneWidget);
  });

  testWidgets('uses a constrained dialog on wide windows', (tester) async {
    await _setWindowSize(tester, const Size(900, 900));
    await tester.pumpWidget(_EditorLauncher());

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final dialog = find.byKey(const Key('acquisition-endpoint-dialog'));
    expect(dialog, findsOneWidget);
    expect(find.byKey(const Key('acquisition-endpoint-sheet')), findsNothing);
    expect(
      find.descendant(
        of: dialog,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox && widget.constraints.maxWidth == 560 && widget.constraints.maxHeight == 760,
        ),
      ),
      findsOneWidget,
    );
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
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged, isNull);
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
