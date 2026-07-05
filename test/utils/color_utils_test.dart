import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/utils/color_utils.dart';

void main() {
  group('parseHexColor', () {
    test('6-digit RGB', () {
      expect(parseHexColor('#FFFFFF'), const Color(0xFFFFFFFF));
      expect(parseHexColor('#000000'), const Color(0xFF000000));
    });

    test('8-digit CSS RRGGBBAA', () {
      expect(parseHexColor('#000000CC'), const Color(0xCC000000));
    });

    test('8-digit Flutter AARRGGBB', () {
      expect(parseHexColor('#FF000000'), const Color(0xFF000000));
    });
  });

  group('colorToHex / normalizeHexColor', () {
    test('colorToHex roundtrip', () {
      const c = Color(0xFFFFD700);
      expect(colorToHex(c), '#FFD700');
      expect(parseHexColor(colorToHex(c)), c);
    });

    test('normalizeHexColor accepts partial input', () {
      expect(normalizeHexColor('ffd700'), '#FFD700');
      expect(normalizeHexColor('#abc'), null);
    });

    test('colorToRgb and colorFromRgb roundtrip', () {
      const color = Color(0xFFFF5722);
      final rgb = colorToRgb(color);
      expect(rgb.r, 255);
      expect(rgb.g, 87);
      expect(rgb.b, 34);
      expect(colorFromRgb(rgb.r, rgb.g, rgb.b), color);
    });

    test('parseRgbChannel validates range', () {
      expect(parseRgbChannel('128'), 128);
      expect(parseRgbChannel('256'), null);
      expect(parseRgbChannel('-1'), null);
    });
  });
}
