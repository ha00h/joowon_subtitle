import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/models/slide_elements.dart';
import 'package:joowon_subtitle/services/sub_io.dart';

void main() {
  group('saechansonggaVerseLabelText', () {
    test('일반 절', () {
      expect(
        saechansonggaVerseLabelText(
          hymnNumber: 8,
          tag: '1절',
          isLastVerse: false,
        ),
        '새찬송가 8장 1절',
      );
    });

    test('마지막 절', () {
      expect(
        saechansonggaVerseLabelText(
          hymnNumber: 8,
          tag: '4절',
          isLastVerse: true,
        ),
        '새찬송가 8장 4절 마지막',
      );
    });

    test('후렴은 빈 문자열', () {
      expect(
        saechansonggaVerseLabelText(
          hymnNumber: 100,
          tag: '후렴구1',
          isLastVerse: false,
        ),
        '',
      );
    });
  });

  group('verseLabelTextForSlide', () {
    test('후렴 슬라이드는 null', () {
      final slides = [
        const Slide(
          elements: [],
          tag: '1절',
        ),
        const Slide(elements: [], tag: '후렴구1'),
      ];
      expect(
        verseLabelTextForSlide(
          slide: slides[1],
          allSlides: slides,
          hymnNumber: 8,
        ),
        isNull,
      );
    });

    test('후렴 뒤에 있어도 마지막 절은 번호 절', () {
      const hymn = '''(1)
a
b

(2)
c

후렴:
d''';
      final sub = SubIo().fromHymnTxt(
        content: hymn,
        title: 't',
        hymnNumber: 8,
      );
      final verse2 = sub.slides.firstWhere((s) => s.tag == '2절');
      final label = findVerseLabelElement(verse2.elements);
      expect(label?.lines, ['새찬송가 8장 2절 마지막']);

      final refrain = sub.slides.firstWhere((s) => s.tag == '후렴구1');
      expect(slideHasVerseLabel(refrain.elements), isFalse);
    });
  });

  group('fromHymnTxt hymnNumber', () {
    const hymn = '''(1)
첫 줄
둘째 줄

(2)
셋째 줄
넷째 줄

(3)
다섯째 줄''';

    test('곡 번호·마지막 절 표기', () {
      final sub = SubIo().fromHymnTxt(
        content: hymn,
        title: '테스트',
        hymnNumber: 8,
      );
      final first = findVerseLabelElement(sub.slides.first.elements);
      expect(first?.lines, ['새찬송가 8장 1절']);

      final lastTagged = sub.slides.lastWhere((s) => s.tag == '3절');
      final lastLabel = findVerseLabelElement(lastTagged.elements);
      expect(lastLabel?.lines, ['새찬송가 8장 3절 마지막']);
    });

    test('같은 절 연속 슬라이드에도 절 표기', () {
      const twoSlidesInVerse = '''(1)첫 줄
둘째 줄
셋째 줄
넷째 줄

(2)다섯째''';
      final sub = SubIo().fromHymnTxt(
        content: twoSlidesInVerse,
        title: '테스트',
        hymnNumber: 8,
      );
      final verse1Second = sub.slides[1];
      expect(verse1Second.tag, isNull);
      expect(slideHasVerseLabel(verse1Second.elements), isTrue);
      expect(
        findVerseLabelElement(verse1Second.elements)?.lines,
        ['새찬송가 8장 1절'],
      );
    });
  });
}
