import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_user_messages.dart';
import 'package:papyrus/auth/auth_api_client.dart';

void main() {
  group('searchErrorMessage', () {
    test('uses the session-expired message for unauthorized API errors', () {
      expect(
        searchErrorMessage(const AuthApiException(statusCode: 401, message: 'raw server response')),
        'Your session expired. Sign in and try again.',
      );
      expect(
        searchErrorMessage(const AuthApiException(statusCode: 403, message: 'raw server response')),
        'Your session expired. Sign in and try again.',
      );
    });

    test('uses the indexer guidance for unavailable connected sources', () {
      for (final statusCode in [502, 503, 504]) {
        expect(
          searchErrorMessage(AuthApiException(statusCode: statusCode, message: 'raw server response')),
          'Could not search connected sources. Check the enabled indexers and try again.',
        );
      }
    });

    test('uses the generic search message for other typed and untyped errors', () {
      expect(
        searchErrorMessage(const AuthApiException(statusCode: 422, message: 'raw server response')),
        'Could not search connected sources. Try again.',
      );
      expect(
        searchErrorMessage(StateError('https://server.local/secret')),
        'Could not search connected sources. Try again.',
      );
    });
  });

  group('submissionErrorMessage', () {
    test('hides authentication details', () {
      expect(
        submissionErrorMessage('Authentication failed at https://client.local/api'),
        'The download client rejected its saved sign-in details.',
      );
    });

    test('hides timeout details', () {
      expect(submissionErrorMessage('request timed out after 30s'), 'The download client did not respond in time.');
      expect(
        submissionErrorMessage('timeout while contacting endpoint-17'),
        'The download client did not respond in time.',
      );
    });

    test('hides release rejection details', () {
      expect(
        submissionErrorMessage('qBittorrent rejected the magnet URL'),
        'The download client rejected this release.',
      );
    });

    test('uses a safe fallback for unknown or absent details', () {
      expect(
        submissionErrorMessage('remote client said: https://client.local/path'),
        'This release could not be sent to the download client.',
      );
      expect(submissionErrorMessage(null), 'This release could not be sent to the download client.');
    });
  });
}
