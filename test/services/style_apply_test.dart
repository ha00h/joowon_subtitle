import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/models/slide_elements.dart';
import 'package:joowon_subtitle/models/style_file.dart';
import 'package:joowon_subtitle/providers/playback_provider.dart';

void main() {
  group('applyStyleConfigToTextElement', () {
    const element = SlideElement(
      id: 't1',
      type: SlideElementType.text,
      x: 10,
      y: 20,
      zIndex: 1,
      lines: ['가사'],
      fontSize: 40,
      color: '#FF0000',
    );

  const style = TextStyleConfig(
      fontFamily: 'Noto Serif',
      fontSize: 72,
      fontWeight: 700,
      color: '#FFD700',
      textShadow: 'none',
      defaultPosition: (x: 50, y: 55),
      strokeWidth: 2,
      strokeColor: '#000000',
      textAlign: 'center',
    );

    test('copies style fields and position', () {
      final updated = applyStyleConfigToTextElement(
        element,
        style,
        x: 50,
        y: 55,
      );
      expect(updated.fontFamily, 'Noto Serif');
      expect(updated.fontSize, 72);
      expect(updated.color, '#FFD700');
      expect(updated.textStrokeWidth, 2);
      expect(updated.x, 50);
      expect(updated.y, 55);
      expect(updated.lines, ['가사']);
    });

    test('ignores non-text elements', () {
      const shape = SlideElement(
        id: 's1',
        type: SlideElementType.shape,
        x: 10,
        y: 20,
        zIndex: 0,
        shapeType: ShapeType.rect,
      );
      expect(
        applyStyleConfigToTextElement(shape, style, x: 50, y: 55),
        shape,
      );
    });
  });
}
