# OPDS support

Papyrus can browse OPDS 1.2 (Atom/XML) and OPDS 2.0 (JSON) catalogs and import direct downloads into the active library.

## Using catalogs

1. Open **Library → Catalogs**. On a narrow screen, open **Library sections** first.
2. Select **Add catalog** and enter a name and the catalog's HTTP or HTTPS URL. Enter a username and password if the catalog uses HTTP Basic authentication.
3. Open the catalog, browse its sections or use keyword search, and select a publication to see details and available downloads.
4. Select a supported format. Progress appears above the catalog. Downloads continue when you navigate elsewhere in Papyrus. Use **Open book** after the import finishes.

Web imports support EPUB. Native imports support EPUB, PDF, MOBI, AZW3, TXT, CBZ, and CBR, matching the existing file importer. The short final **Adding to library** step cannot be cancelled; earlier download and processing steps can. Failed downloads offer Retry.

Catalog settings stay on this device, separately for each server/account and for the guest library. Credentials are stored through the platform's secure-storage implementation, separately from catalog preferences and bound to the catalog origin. Removing a catalog also removes its credentials; downloaded books remain in your library. On an existing catalog, leave the credentials blank to retain them, or select **Remove saved credentials**. Changing its URL origin clears saved credentials unless replacement credentials are entered.

Imported books use the existing local file storage, metadata persistence, cover handling, and media-upload queue. Embedded book metadata takes precedence; catalog metadata fills missing values. Signed-in libraries retain their existing synchronization behavior. Switching accounts invalidates in-flight OPDS work before it can import into the newly selected library.

## Compatibility and troubleshooting

- Catalogs connect directly from the client. Web access requires CORS permission from the catalog, including permission for the Authorization header on protected catalogs. Browsers can also block HTTP catalogs from an HTTPS application. Use the native app or configure the catalog's browser access when necessary.
- Authentication supports HTTP Basic. Use HTTPS to protect credentials in transit. Papyrus account tokens are never added to catalog requests; credentials are not forwarded to another origin.
- Browsing includes groups, facets, pagination, complete publication entries, and advertised keyword search. OPDS 1.2 uses OpenSearch descriptions; OPDS 2.0 uses URI templates.
- Purchases, loans, subscriptions, DRM, indirect acquisition, and OAuth are displayed as unsupported acquisition methods. Papyrus does not follow those links as book downloads.
- This version does not sync catalog settings, cache catalogs for offline browsing, or resume downloads after the app closes.
- Feed, search-description, and image responses are limited to 8 MiB; book downloads to 256 MiB. A request or stalled stream times out after 30 seconds. These limits protect the current in-memory import pipeline.
- Authentication errors offer guidance to edit credentials. Network errors offer retry and browser-policy guidance without claiming to distinguish a CORS failure from other browser network failures.

## Implementation

The `lib/opds` module separates normalized models, XML/JSON parsing, search expansion, scoped persistence, HTTP transport, browsing state, and application-scoped downloads. `BookImportSession` captures the existing import destination and supplies the shared `BookImportCommitService` composition used by OPDS and file-import widgets.

The routes `/library/catalogs` and `/library/catalogs/:catalogId` live inside the existing Library shell. The `feed` query parameter stores the current resource URL, and `q` retains the displayed keyword query. Neither contains Basic credentials. Browser history and refresh reload the selected feed.

No server API, database schema, or dependency changes are required.

## Verification

From `client/app`, run:

```sh
flutter test --coverage
flutter analyze --no-fatal-warnings --no-fatal-infos
dart format --output=none --set-exit-if-changed lib test
flutter build web --no-pub
flutter build linux --no-pub
```

Network smoke tests use a local fixture server and are skipped in the normal suite. Start it in a separate terminal:

```sh
python3 tool/opds_fixture_server.py --port 8766
```

Then run the same tests on the Linux Dart VM and Chrome:

```sh
flutter test test/opds/network_smoke_test.dart --no-pub --dart-define=OPDS_SMOKE_URL=http://127.0.0.1:8766
flutter test test/opds/network_smoke_test.dart --no-pub --platform chrome --dart-define=OPDS_SMOKE_URL=http://127.0.0.1:8766
```

The fixtures cover public and Basic-auth catalogs in both formats, browsing, details, search, pagination, EPUB bytes, redirect URL resolution, authentication failures, and cross-origin credential stripping. They use the test credentials `reader` / `secret` and bind only to localhost.

### Implementation verification — 2026-09-06

- Full Flutter suite: 1,200 passed, 18 skipped (including the eight opt-in network smoke tests).
- Real HTTP smoke suite: eight passed on the Linux Dart VM and eight passed in Chrome.
- Flutter analysis: no issues. Formatting verification: 402 Dart files checked, no changes. Git whitespace check passed.
- Web and Linux production builds passed.
- Built web application: verified guest catalog browsing and EPUB download/import into the library, then entered Basic credentials through the catalog editor and browsed the protected catalog. Checked the desktop layout visually; responsive/e-ink widget tests cover narrow and wide screens.
- Independent specification and code reviews completed; their credential, account-transition, facet, search, response-validation, and cancellation findings were fixed and covered by regression tests.
