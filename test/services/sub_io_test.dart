import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/models/slide_elements.dart';
import 'package:joowon_subtitle/models/style_file.dart';
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

    test('S-02b: fromHymnTxt creates verse labels', () {
      const hymn = '''(1)
첫 줄 가사
둘째 줄 가사

후렴:
후렴 첫 줄
후렴 둘째 줄''';
      final sub = subIo.fromHymnTxt(
        content: hymn,
        title: '찬송가',
        style: StyleFile.defaultStyle,
      );
      expect(sub.slides.length, greaterThan(1));
      final first = sub.slides.first;
      expect(first.tag, '1절');
      expect(slideHasVerseLabel(first.elements), isTrue);
      final label = findVerseLabelElement(first.elements);
      expect(label?.lines, ['1절']);
    });

    test('S-02b2: fromHymnTxt with hymnNumber uses 장절 표기', () {
      const hymn = '''(1)
첫 줄 가사
둘째 줄 가사

(2)
셋째 줄''';
      final sub = subIo.fromHymnTxt(
        content: hymn,
        title: '찬송가',
        style: StyleFile.defaultStyle,
        hymnNumber: 8,
      );
      final first = findVerseLabelElement(sub.slides.first.elements);
      expect(first?.lines, ['새찬송가 8장 1절']);
      final lastTagged = sub.slides.lastWhere((s) => s.tag != null);
      final lastLabel = findVerseLabelElement(lastTagged.elements);
      expect(lastLabel?.lines, ['새찬송가 8장 2절 마지막']);
    });

    test('S-02c: fromHymnTxt onlyFirstVerse', () {
      const hymn = '''(1)
첫 줄
둘째 줄

(2)
셋째 줄
넷째 줄''';
      final sub = subIo.fromHymnTxt(
        content: hymn,
        title: '찬송가',
        onlyFirstVerse: true,
      );
      expect(sub.slides.length, 2);
      expect(sub.slides.first.tag, '1절');
      expect(sub.slides[1].tag, isNull);
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
