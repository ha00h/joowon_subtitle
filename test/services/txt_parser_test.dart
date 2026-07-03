import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/services/txt_parser.dart';

void main() {
  group('parseTxtToSlides', () {
    test('T-01: blank line splits slides (MVP example)', () {
      const content = '''주님의 마음 내게 주사
내 마음 기쁨 넘치네

거룩하신 주님 앞에
모든 것 드립니다
영광과 존귀

할렐루야
찬양해''';

      final slides = parseTxtToSlides(content);
      expect(slides.length, 3);
      expect(slides[0], ['주님의 마음 내게 주사', '내 마음 기쁨 넘치네']);
      expect(slides[1].length, 3);
      expect(slides[2], ['할렐루야', '찬양해']);
    });

    test('T-02: consecutive blank lines', () {
      const content = 'A\n\n\nB';
      final slides = parseTxtToSlides(content);
      expect(slides.length, 2);
      expect(slides[0], ['A']);
      expect(slides[1], ['B']);
    });

    test('T-03: trailing newlines', () {
      const content = 'A\n\n';
      final slides = parseTxtToSlides(content);
      expect(slides.length, 1);
      expect(slides[0], ['A']);
    });
  });
}
