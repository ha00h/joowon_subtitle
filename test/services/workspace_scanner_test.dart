import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/services/sub_io.dart';
import 'package:joowon_subtitle/services/workspace_scanner.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late SubIo subIo;
  late WorkspaceScanner scanner;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('joowon_scan_');
    subIo = SubIo();
    scanner = WorkspaceScanner(subIo: subIo);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  void writeSub(String relativePath, String title) {
    final path = p.join(tempDir.path, relativePath);
    File(path).parent.createSync(recursive: true);
    subIo.writeFile(
      path,
      subIo.fromTxt(content: 'line1\n\nline2', title: title),
    );
  }

  group('WorkspaceScanner', () {
    test('W-01: flat folder', () {
      writeSub('a.sub', 'A');
      writeSub('b.sub', 'B');
      final entries = scanner.scanSubFiles(tempDir.path);
      expect(entries.length, 2);
    });

    test('W-02: nested folder', () {
      writeSub('2024/song.sub', '중첩');
      final entries = scanner.scanSubFiles(tempDir.path);
      expect(entries.length, 1);
      expect(entries.first.relativePath, p.join('2024', 'song.sub'));
    });

    test('W-03: duplicate titles', () {
      writeSub('a/one.sub', '같은제목');
      writeSub('b/two.sub', '같은제목');
      final entries = scanner.scanSubFiles(tempDir.path);
      expect(entries.length, 2);
      expect(entries.every((e) => e.title == '같은제목'), isTrue);
    });
  });
}
