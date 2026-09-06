import 'package:papyrus/opds/opds_http_client.dart';
import 'package:web/web.dart' as web;

/// A user-initiated navigation allows saving a file without reading it via CORS.
/// Saved Basic credentials are deliberately not transferred to the browser tab.
void openOpdsDownload(Uri uri) {
  OpdsHttpClient.validateUri(uri);
  final anchor = web.HTMLAnchorElement()
    ..href = uri.toString()
    ..target = '_blank'
    ..rel = 'noopener noreferrer'
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
