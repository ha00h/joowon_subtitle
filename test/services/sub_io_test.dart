import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/models/sub_file.dart';
import 'package:joowon_subtitle/services/sub_io.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late SubIo subIo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('joowon_test_');
    subIo = SubIo();
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('SubIo', () {
    test('S-01: round-trip json', () {
      final sub = SubFile(
        title: '테스트',
        slides: const [],
      );
      final path = p.join(tempDir.path, 'test.sub');
      subIo.writeFile(path, sub);
      final loaded = subIo.readFile(path);
      expect(loaded.title, '테스트');
      expect(loaded.version, 2);
    });

    test('S-02: fromTxt creates slides', () async {
      final txt = await File(p.join('test', 'fixtures', 'sample.txt')).readAsString();
      final sub = subIo.fromTxt(content: txt, title: '주님의 마음');
      expect(sub.slides.length, 3);
      expect(sub.slides.first.elements.first.lines?.length, 2);
    });

    test('S-03: v1 import converts to v2', () {
      const v1Json = '''
{
  "format": "joowon-subtitle",
  "version": 1,
  "title": "v1곡",
  "slides": [
    { "lines": ["1절", "2절"] }
  ]
}''';
      final sub = subIo.readJson(v1Json);
      expect(sub.slides.first.elements.first.type.name, 'text');
      expect(sub.slides.first.elements.first.lines, ['1절', '2절']);
    });
  });
}
