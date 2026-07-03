import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/style_file.dart';
import 'style_io.dart';

class StyleEntry {
  const StyleEntry({
    required this.name,
    required this.style,
    required this.path,
  });

  final String path;
  final String name;
  final StyleFile style;
}

class StyleStore {
  StyleStore({StyleIo? styleIo}) : _styleIo = styleIo ?? StyleIo();

  final StyleIo _styleIo;

  static String? testDirectoryOverride;

  static const defaultFileName = '기본.style';

  Future<String> directoryPath() async {
    if (testDirectoryOverride != null) {
      final dir = Directory(testDirectoryOverride!);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return testDirectoryOverride!;
    }

    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'styles'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  Future<void> ensureDefaultStyle() async {
    final dir = await directoryPath();
    final defaultPath = p.join(dir, defaultFileName);
    if (!File(defaultPath).existsSync()) {
      _styleIo.writeFile(defaultPath, StyleFile.defaultStyle);
    }
  }

  Future<List<StyleEntry>> listStyles() async {
    final dir = await directoryPath();
    final root = Directory(dir);
    if (!root.existsSync()) return [];

    final results = <StyleEntry>[];
    for (final entity in root.listSync(followLinks: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.style') continue;

      try {
        final style = _styleIo.readFile(entity.path);
        results.add(
          StyleEntry(
            path: entity.path,
            name: style.name,
            style: style,
          ),
        );
      } catch (_) {
        // skip corrupt files
      }
    }

    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  Future<String> createStyle(StyleFile style) async {
    final dir = await directoryPath();
    final slug = _slugify(style.name);
    final path = _uniquePath(dir, slug);
    _styleIo.writeFile(path, style);
    return path;
  }

  Future<String> saveStyle(String path, StyleFile style) async {
    _styleIo.writeFile(path, style);
    return path;
  }

  Future<String> importExternalStyle(String sourcePath) async {
    final style = _styleIo.readFile(sourcePath);
    return createStyle(style);
  }

  Future<void> deleteStyle(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  StyleEntry? findByPath(List<StyleEntry> entries, String? path) {
    if (path == null) return null;
    for (final entry in entries) {
      if (entry.path == path) return entry;
    }
    return null;
  }

  String _slugify(String name) {
    var slug = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w가-힣]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (slug.isEmpty) slug = 'style';
    return slug;
  }

  String _uniquePath(String dir, String baseSlug) {
    var candidate = p.join(dir, '$baseSlug.style');
    if (!File(candidate).existsSync()) return candidate;

    var index = 2;
    while (File(p.join(dir, '${baseSlug}_$index.style')).existsSync()) {
      index++;
    }
    return p.join(dir, '${baseSlug}_$index.style');
  }
}
