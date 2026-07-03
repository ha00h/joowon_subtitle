import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:joowon_subtitle/services/update_service.dart';

void main() {
  group('UpdateService', () {
    late UpdateService service;

    setUp(() {
      service = UpdateService();
    });

    test('isNewerVersion compares semver', () {
      expect(service.isNewerVersion('0.9.1', '1.0.0'), isTrue);
      expect(service.isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(service.isNewerVersion('1.1.0', '1.0.9'), isFalse);
    });

    test('fetchLatestRelease parses GitHub release JSON', () async {
      final client = _FakeClient(
        body: jsonEncode({
          'tag_name': 'v1.2.0',
          'html_url': 'https://github.com/ha00h/joowon_subtitle/releases/tag/v1.2.0',
          'body': '## Changes\n- bug fix',
          'assets': [
            {
              'name': 'joowon-subtitle-1.2.0-windows.zip',
              'browser_download_url':
                  'https://example.com/joowon-subtitle-1.2.0-windows.zip',
            },
            {
              'name': 'joowon-subtitle-1.2.0-macos.zip',
              'browser_download_url':
                  'https://example.com/joowon-subtitle-1.2.0-macos.zip',
            },
          ],
        }),
      );
      service = UpdateService(client: client);

      final release = await service.fetchLatestRelease();
      expect(release, isNotNull);
      expect(release!.version, '1.2.0');
      expect(
        release.releasePageUrl,
        'https://github.com/ha00h/joowon_subtitle/releases/tag/v1.2.0',
      );
      expect(release.releaseNotes, contains('bug fix'));
    });

    test('fetchLatestRelease throws on API error', () async {
      service = UpdateService(client: _FakeClient(statusCode: 404));

      expect(
        () => service.fetchLatestRelease(),
        throwsA(isA<UpdateCheckException>()),
      );
    });
  });
}

class _FakeClient extends http.BaseClient {
  _FakeClient({this.body = '{}', this.statusCode = 200});

  final String body;
  final int statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
    );
  }
}
