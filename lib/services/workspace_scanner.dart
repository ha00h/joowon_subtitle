import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/natural_compare.dart';
import 'sub_io.dart';

class SubFileEntry {
  const SubFileEntry({
    required this.path,
    required this.title,
    required this.relativePath,
  });

  final String path;
  final String title;
  final String relativePath;

  /// 파일명 앞자리 번호 (예: `001_만복의_근원_하나님.sub` → 1)
  int? get hymnNumber {
    final base = p.basenameWithoutExtension(relativePath);
    final match = RegExp(r'^(\d+)').firstMatch(base);
    if (match == null) return null;
    return int.parse(match.group(1)!);
  }

  String get listTitle {
    final number = hymnNumber;
    if (number == null) return title;
    return '$number. $title';
  }

  String get searchHaystack {
    final parts = <String>[title, relativePath];
    final number = hymnNumber;
    if (number != null) {
      parts
        ..add(number.toString())
        ..add(number.toString().padLeft(3, '0'));
    }
    return parts.join('\n').toLowerCase();
  }
}

class WorkspaceScanner {
  WorkspaceScanner({SubIo? subIo}) : _subIo = subIo ?? SubIo();

  final SubIo _subIo;

  List<SubFileEntry> scanSubFiles(String rootPath) {
    final root = Directory(rootPath);
    if (!root.existsSync()) return [];

    final results = <SubFileEntry>[];
    try {
      for (final entity
          in root.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        if (p.extension(entity.path).toLowerCase() != '.sub') continue;

        try {
          final sub = _subIo.readFile(entity.path);
          results.add(
            SubFileEntry(
              path: entity.path,
              title: sub.title,
              relativePath: p.relative(entity.path, from: rootPath),
            ),
          );
        } catch (_) {
          // skip corrupt files
        }
      }
    } on PathAccessException {
      return [];
    } on FileSystemException {
      return [];
    }
    results.sort(
      (a, b) => naturalCompare(a.relativePath, b.relativePath),
    );
    return results;
  }

  List<SubFileEntry> search(List<SubFileEntry> entries, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return entries;

    final tokens = trimmed
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty);

    return entries
        .where(
          (entry) => tokens.every(entry.searchHaystack.contains),
        )
        .toList();
  }
}
