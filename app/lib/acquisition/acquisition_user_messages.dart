import 'package:papyrus/auth/auth_api_client.dart';

String searchErrorMessage(Object error) {
  if (error is AuthApiException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Your session expired. Sign in and try again.';
    }

    if (error.statusCode == 502 || error.statusCode == 503 || error.statusCode == 504) {
      return 'Could not search connected sources. Check the enabled indexers and try again.';
    }
  }

  return 'Could not search connected sources. Try again.';
}

String submissionErrorMessage(String? detail) {
  final normalized = detail?.toLowerCase() ?? '';

  if (normalized.contains('auth')) {
    return 'The download client rejected its saved sign-in details.';
  }

  if (normalized.contains('timeout') || normalized.contains('timed out')) {
    return 'The download client did not respond in time.';
  }

  if (normalized.contains('reject')) {
    return 'The download client rejected this release.';
  }

  return 'This release could not be sent to the download client.';
}

String configurationErrorMessage(Object _) => 'Could not load download settings. Try again.';

String jobRefreshErrorMessage(Object _) => 'Could not refresh downloads. Try again.';

String cancelDownloadErrorMessage(Object _) => 'Could not cancel the download. Try again.';

String removeDownloadErrorMessage(Object _) => 'Could not remove the download. Try again.';

String listDownloadFilesErrorMessage(Object _) => 'Could not load download files. Try again.';

String selectDownloadFileErrorMessage(Object _) => 'Could not select the download file. Try again.';

String retryDownloadImportErrorMessage(Object _) => 'Could not retry the download import. Try again.';
