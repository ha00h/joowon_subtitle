import 'dart:io';

import 'package:path/path.dart' as p;

String sanitizeSubBaseName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  var name = trimmed;
  if (name.toLowerCase().endsWith('.sub')) {
    name = p.basenameWithoutExtension(name);
  }

  return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
}

/// 파일명(확장자 제외)에서 목록·송출에 쓸 제목을 추출합니다.
/// 예: `001_만복의_근원_하나님` → `만복의 근원 하나님`
String titleFromSubBaseName(String baseName) {
  final trimmed = baseName.trim();
  final match = RegExp(r'^(\d+)[_\-]?(.*)$').firstMatch(trimmed);
  if (match != null) {
    final rest = match.group(2)!.replaceAll('_', ' ').trim();
    if (rest.isNotEmpty) return rest;
  }
  return trimmed.replaceAll('_', ' ').trim();
}

Future<String> renameSubFile({
  required String oldPath,
  required String newBaseName,
}) async {
  final sanitized = sanitizeSubBaseName(newBaseName);
  if (sanitized.isEmpty) {
    throw const FormatException('파일 이름을 입력하세요');
  }

  final newPath = p.join(p.dirname(oldPath), '$sanitized.sub');
  if (p.normalize(newPath) == p.normalize(oldPath)) {
    return oldPath;
  }

  final target = File(newPath);
  if (target.existsSync()) {
    throw const FileSystemException('같은 이름의 파일이 이미 있습니다');
  }

  await File(oldPath).rename(newPath);
  return newPath;
}
