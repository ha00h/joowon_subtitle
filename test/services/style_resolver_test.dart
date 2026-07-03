import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/models/resolved_text_style.dart';
import 'package:joowon_subtitle/models/slide_elements.dart';
import 'package:joowon_subtitle/models/style_file.dart';

void main() {
  group('StyleResolver', () {
    const element = SlideElement(
      id: 't1',
      type: SlideElementType.text,
      x: 50,
      y: 50,
      zIndex: 1,
      lines: ['test'],
      fontSize: 80,
    );

    test('ST-01: app default', () {
      const resolver = StyleResolver();
      final style = resolver.resolveText(element);
      expect(style.fontSize, 80);
      expect(style.fontFamily, 'Noto Sans KR');
    });

    test('ST-03: element override wins', () {
      const styleFile = StyleFile(
        name: 's',
        text: TextStyleConfig(
          fontFamily: 'Nanum Gothic',
          fontSize: 60,
          fontWeight: 400,
          color: '#FF0000',
          textShadow: 'none',
          defaultPosition: (x: 50, y: 50),
        ),
      );
      const resolver = StyleResolver(styleFile: styleFile);
      final style = resolver.resolveText(element);
      expect(style.fontSize, 80);
      expect(style.fontFamily, 'Nanum Gothic');
    });

    test('element stroke and shadow override', () {
      const elementWithEffects = SlideElement(
        id: 't2',
        type: SlideElementType.text,
        x: 50,
        y: 50,
        zIndex: 1,
        lines: ['test'],
        textStrokeWidth: 3,
        textStrokeColor: '#FF0000',
        shadowEnabled: true,
        shadowOffsetX: 4,
        shadowOffsetY: 4,
        shadowBlur: 8,
        shadowColor: '#000000CC',
      );
      const resolver = StyleResolver();
      final style = resolver.resolveText(elementWithEffects);
      expect(style.strokeWidth, 3);
      expect(style.strokeColor, '#FF0000');
      expect(style.shadow.enabled, isTrue);
      expect(style.shadow.offsetX, 4);
      expect(style.shadow.color, '#000000CC');
    });
  });
}
