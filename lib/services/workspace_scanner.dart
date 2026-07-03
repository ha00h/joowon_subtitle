import 'dart:io';

import 'package:path/path.dart' as p;

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
    results.sort((a, b) => a.title.compareTo(b.title));
    return results;
  }

  List<SubFileEntry> search(List<SubFileEntry> entries, String query) {
    if (query.trim().isEmpty) return entries;
    final q = query.toLowerCase();
    return entries
        .where(
          (e) =>
              e.title.toLowerCase().contains(q) ||
              e.relativePath.toLowerCase().contains(q),
        )
        .toList();
  }
}
