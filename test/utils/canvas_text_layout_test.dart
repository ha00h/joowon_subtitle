import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/models/resolved_text_style.dart';
import 'package:joowon_subtitle/models/slide_elements.dart';
import 'package:joowon_subtitle/utils/canvas_text_layout.dart';

void main() {
  group('canvas_text_layout', () {
    const style = ResolvedTextStyle(
      fontFamily: 'Noto Sans KR',
      fontSize: 72,
      fontWeight: 700,
      color: '#FFFFFF',
      textShadow: 'none',
    );

    test('measureTextBlockSize grows with line count', () {
      final one = measureTextBlockSize(
        lines: const ['주님의 마음'],
        style: style,
        canvasWidth: 960,
      );
      final two = measureTextBlockSize(
        lines: const ['주님의 마음', '내게 주사'],
        style: style,
        canvasWidth: 960,
      );
      expect(two.height, greaterThan(one.height));
      expect(two.width, greaterThanOrEqualTo(one.width));
    });

    test('textElementScreenRect uses top-left when anchor is topLeft', () {
      const element = SlideElement(
        id: 't1',
        type: SlideElementType.text,
        x: 10,
        y: 20,
        zIndex: 1,
        lines: ['가사'],
        anchor: 'topLeft',
      );
      final rect = textElementScreenRect(
        element: element,
        style: style,
        canvasWidth: 800,
        canvasHeight: 450,
      );
      expect(rect.topLeft, const Offset(80, 90));
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
    });

    test('textElementScreenRect is centered when anchor is center', () {
      const element = SlideElement(
        id: 't1',
        type: SlideElementType.text,
        x: 50,
        y: 50,
        zIndex: 1,
        lines: ['가사'],
        anchor: 'center',
      );
      final rect = textElementScreenRect(
        element: element,
        style: style,
        canvasWidth: 800,
        canvasHeight: 450,
      );
      expect(rect.center, const Offset(400, 225));
    });

    test('textElementScreenRect uses width and height box when set', () {
      const element = SlideElement(
        id: 't1',
        type: SlideElementType.text,
        x: 8,
        y: 10,
        width: 85,
        height: 50,
        zIndex: 1,
        lines: ['가사'],
        anchor: 'topLeft',
      );
      final rect = textElementScreenRect(
        element: element,
        style: style,
        canvasWidth: 800,
        canvasHeight: 450,
      );
      expect(rect.left, 64);
      expect(rect.top, 45);
      expect(rect.width, 680);
      expect(rect.height, 225);
    });

    test('canvasTextAlign maps strings', () {
      expect(canvasTextAlign('left'), TextAlign.left);
      expect(canvasTextAlign('right'), TextAlign.right);
      expect(canvasTextAlign('center'), TextAlign.center);
      expect(canvasTextAlign(null), TextAlign.center);
    });
  });
}
