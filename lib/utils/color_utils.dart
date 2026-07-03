import 'package:flutter/material.dart';

/// `#RRGGBB` 또는 `#RRGGBBAA`(CSS) / `#AARRGGBB`(Flutter) hex를 Color로 변환
Color parseHexColor(String hex) {
  var value = hex.trim().replaceFirst('#', '').toUpperCase();
  if (value.length == 8) {
    // RRGGBBAA (CSS) → AARRGGBB (Flutter)
    if (_isCssRgbaOrder(value)) {
      value = value.substring(6, 8) + value.substring(0, 6);
    }
  } else if (value.length == 6) {
    value = 'FF$value';
  } else {
    throw FormatException('Invalid hex color: $hex');
  }
  return Color(int.parse(value, radix: 16));
}

/// alpha가 끝에 오는 CSS 스타일 (#RRGGBBAA)인지 추정
bool _isCssRgbaOrder(String eightChars) {
  final alpha = int.tryParse(eightChars.substring(6, 8), radix: 16);
  final leading = int.tryParse(eightChars.substring(0, 2), radix: 16);
  // alpha가 trailing이면 보통 00~FF, leading byte가 FF면 Flutter AARRGGBB일 수 있음
  if (leading == 0xFF) return false;
  return alpha != null && alpha > 0;
}

/// Color → `#RRGGBB` 또는 `#RRGGBBAA`(supportsAlpha)
String colorToHex(Color color, {bool withAlpha = false}) {
  final r = _channelHex(color.r);
  final g = _channelHex(color.g);
  final b = _channelHex(color.b);
  final a = _channelHex(color.a);
  if (!withAlpha || a == 'FF') return '#$r$g$b';
  return '#$r$g$b$a';
}

String _channelHex(double channel) {
  return (channel * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();
}

Color? tryParseHexColor(String hex) {
  try {
    return parseHexColor(hex);
  } catch (_) {
    return null;
  }
}

/// 입력 hex를 `#RRGGBB` / `#RRGGBBAA` 형식으로 정규화. 실패 시 null.
String? normalizeHexColor(String input, {bool allowAlpha = false}) {
  var value = input.trim().replaceFirst('#', '').toUpperCase();
  if (!allowAlpha && value.length == 8) {
    value = value.substring(0, 6);
  }
  if (value.length == 6 || (allowAlpha && value.length == 8)) {
    if (!RegExp(r'^[0-9A-F]+$').hasMatch(value)) return null;
    return '#$value';
  }
  return null;
}
