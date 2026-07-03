import 'dart:io';

import 'package:flutter/services.dart';

class PickedPath {
  const PickedPath({required this.path, this.bookmark});

  final String path;
  final String? bookmark;
}

class SecurityScopedAccess {
  SecurityScopedAccess._();

  static const _channel = MethodChannel(
    'joowon_subtitle/security_scoped_access',
  );

  static bool get isSupported => Platform.isMacOS;

  static Future<PickedPath?> pickDirectory({String? initialDirectory}) async {
    if (!isSupported) return null;
    final result = await _channel.invokeMethod<Object?>(
      'pickDirectory',
      {'initialDirectory': initialDirectory},
    );
    return _parsePickResult(result);
  }

  static Future<PickedPath?> pickStyleFile({String? initialDirectory}) async {
    if (!isSupported) return null;
    final result = await _channel.invokeMethod<Object?>(
      'pickStyleFile',
      {'initialDirectory': initialDirectory},
    );
    return _parsePickResult(result);
  }

  static Future<String?> restoreBookmark(String bookmark) async {
    if (!isSupported || bookmark.isEmpty) return null;
    return _channel.invokeMethod<String?>(
      'restoreBookmark',
      {'bookmark': bookmark},
    );
  }

  static PickedPath? _parsePickResult(Object? result) {
    if (result is! Map) return null;
    final path = result['path'];
    if (path is! String || path.isEmpty) return null;
    final bookmark = result['bookmark'];
    return PickedPath(
      path: path,
      bookmark: bookmark is String && bookmark.isNotEmpty ? bookmark : null,
    );
  }
}
