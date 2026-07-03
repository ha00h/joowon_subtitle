import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'security_scoped_access.dart';

/// 찬양 작업 폴더 선택 — macOS는 security-scoped bookmark를 함께 반환한다.
Future<PickedPath?> pickWorkspaceDirectory({String? initialDirectory}) async {
  var initial = initialDirectory;
  if (initial != null && !Directory(initial).existsSync()) {
    initial = null;
  }

  if (SecurityScopedAccess.isSupported) {
    return SecurityScopedAccess.pickDirectory(initialDirectory: initial);
  }

  final path = await FilePicker.getDirectoryPath(
    dialogTitle: '찬양 작업 폴더 선택',
    initialDirectory: initial,
  );
  if (path == null) return null;
  return PickedPath(path: path);
}
