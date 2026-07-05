import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/models/slide_elements.dart';

void main() {
  group('Slide colorTag', () {
    test('round-trips through json', () {
      const slide = Slide(
        elements: [],
        tag: '1절',
        colorTag: '#FF5722',
      );

      final json = slide.toJson();
      final restored = Slide.fromJson(json);

      expect(restored.tag, '1절');
      expect(restored.colorTag, '#FF5722');
    });

    test('loads legacy slide without colorTag', () {
      final slide = Slide.fromJson({
        'elements': [],
        'tag': '후렴구1',
      });

      expect(slide.tag, '후렴구1');
      expect(slide.colorTag, isNull);
    });

    test('copyWith can clear colorTag', () {
      const slide = Slide(
        elements: [],
        colorTag: '#3498DB',
      );

      final cleared = slide.copyWith(clearColorTag: true);
      expect(cleared.colorTag, isNull);
      expect(cleared.toJson().containsKey('colorTag'), isFalse);
    });
  });
}
