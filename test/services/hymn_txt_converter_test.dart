import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/services/hymn_txt_converter.dart';

void main() {
  group('convertHymnTxtToSlides', () {
    test('pairs lines within a stanza', () {
      const content = '''
만복의 근원 하나님
온 백성 찬송 드리고
저 천사여 찬송하세
성부 성자 성령 -아멘''';

      final slides = convertHymnTxtToSlides(content);
      expect(slides, hasLength(2));
      expect(slides[0].lines, [
        '만복의 근원 하나님',
        '온 백성 찬송 드리고',
      ]);
      expect(slides[1].lines, [
        '저 천사여 찬송하세',
        '성부 성자 성령 -아멘',
      ]);
    });

    test('blank line starts new stanza and sets verse tag', () {
      const content = '''
(1)거룩 거룩 거룩 전능하신 주님
이른 아침 우리 주를 찬송 합니다

(2)거룩 거룩 거룩 주의 보좌 앞에
모든 성도 면류관을 벗어 드리네''';

      final slides = convertHymnTxtToSlides(content);
      expect(slides, hasLength(2));
      expect(slides[0].tag, '1절');
      expect(slides[1].tag, '2절');
    });

    test('refrain marker becomes tag', () {
      const content = '''
후렴: 할렐루야 찬양해
영원토록 아멘''';

      final slides = convertHymnTxtToSlides(content);
      expect(slides.single.tag, '후렴구1');
      expect(slides.single.lines.first, '할렐루야 찬양해');
    });
  });
}
