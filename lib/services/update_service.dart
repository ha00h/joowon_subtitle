import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

import '../models/app_release_info.dart';

class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  static const githubOwner = 'ha00h';
  static const githubRepo = 'joowon_subtitle';

  final http.Client _client;

  Future<String> currentVersion() async {
    const override = String.fromEnvironment('APP_VERSION_OVERRIDE');
    if (override.isNotEmpty) return override;

    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<AppReleaseInfo?> fetchLatestRelease() async {
    final uri = Uri.parse(
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest',
    );
    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'joowon-subtitle',
      },
    );

    if (response.statusCode != 200) {
      throw UpdateCheckException(
        'GitHub API 오류 (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseRelease(json);
  }

  AppReleaseInfo? _parseRelease(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String?;
    if (tag == null || tag.isEmpty) return null;

    final version = tag.startsWith('v') ? tag.substring(1) : tag;
    final releasePageUrl = json['html_url'] as String?;
    if (releasePageUrl == null || releasePageUrl.isEmpty) return null;

    final assets = json['assets'] as List<dynamic>? ?? [];
    final downloadUrl = _pickDownloadUrl(assets);

    final body = json['body'] as String?;
    final releaseNotes = body == null || body.trim().isEmpty
        ? null
        : _truncateReleaseNotes(body.trim());

    return AppReleaseInfo(
      version: version,
      releasePageUrl: releasePageUrl,
      downloadUrl: downloadUrl,
      releaseNotes: releaseNotes,
    );
  }

  String? _pickDownloadUrl(List<dynamic> assets) {
    final suffix = Platform.isWindows
        ? '-windows.zip'
        : Platform.isMacOS
            ? '-macos.zip'
            : null;
    if (suffix == null) return null;

    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = asset['name'] as String?;
      final url = asset['browser_download_url'] as String?;
      if (name != null && name.endsWith(suffix) && url != null) {
        return url;
      }
    }
    return null;
  }

  String _truncateReleaseNotes(String body, {int maxLines = 8}) {
    final lines = body.split('\n');
    if (lines.length <= maxLines) return body;
    return '${lines.take(maxLines).join('\n')}\n…';
  }

  bool isNewerVersion(String current, String latest) {
    try {
      return Version.parse(latest) > Version.parse(current);
    } on FormatException {
      return latest != current;
    }
  }
}

class UpdateCheckException implements Exception {
  UpdateCheckException(this.message);

  final String message;

  @override
  String toString() => message;
}
