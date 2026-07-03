import 'package:file_picker/file_picker.dart';

import 'security_scoped_access.dart';

/// .style 파일 선택 — macOS는 security-scoped bookmark를 함께 반환한다.
Future<PickedPath?> pickStyleFile({String? initialDirectory}) async {
  if (SecurityScopedAccess.isSupported) {
    return SecurityScopedAccess.pickStyleFile(
      initialDirectory: initialDirectory,
    );
  }

  final result = await FilePicker.pickFiles(
    dialogTitle: '.style 파일 선택',
    type: FileType.custom,
    allowedExtensions: ['style'],
    initialDirectory: initialDirectory,
  );
  if (result == null || result.files.isEmpty) return null;
  final path = result.files.single.path;
  if (path == null) return null;
  return PickedPath(path: path);
}
