import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/resolved_text_style.dart';
import '../models/slide_elements.dart';
import 'color_utils.dart';

const kCanvasFontFallbacks = [
  'Apple SD Gothic Neo',
  'Helvetica Neue',
  'Malgun Gothic',
  'sans-serif',
];

const kCanvasPercentMin = 0.0;
const kCanvasPercentMax = 100.0;
const kRegionMinSizePercent = 5.0;

double canvasFontScale(double canvasWidth) => canvasWidth / 1920;

/// 텍스트 요소의 (x, y) 기준점. [center]만 중심, 그 외는 왼쪽 상단.
bool isCenterAnchored(String? anchor) => anchor == 'center';

Offset anchorFractionalTranslation(String? anchor) {
  if (isCenterAnchored(anchor)) return const Offset(-0.5, -0.5);
  return Offset.zero;
}

TextAlign canvasTextAlign(String? value) {
  switch (value) {
    case 'left':
      return TextAlign.left;
    case 'right':
      return TextAlign.right;
    case 'center':
    default:
      return TextAlign.center;
  }
}

CrossAxisAlignment columnCrossAxisFor(TextAlign align) {
  switch (align) {
    case TextAlign.left:
      return CrossAxisAlignment.start;
    case TextAlign.right:
      return CrossAxisAlignment.end;
    case TextAlign.center:
    case TextAlign.justify:
    case TextAlign.start:
    case TextAlign.end:
      return CrossAxisAlignment.center;
  }
}

TextStyle buildCanvasFillTextStyle(
  ResolvedTextStyle style,
  double canvasWidth,
) {
  final scale = canvasFontScale(canvasWidth);
  final fontSize = style.fontSize * scale;
  final shadows = style.shadowEnabled
      ? [
          Shadow(
            color: parseHexColor(style.shadowColor),
            blurRadius: style.shadowBlur * scale,
            offset: Offset(
              style.shadowOffsetX * scale,
              style.shadowOffsetY * scale,
            ),
          ),
        ]
      : const <Shadow>[];

  return TextStyle(
    fontFamily: style.fontFamily,
    fontFamilyFallback: kCanvasFontFallbacks,
    fontSize: fontSize,
    fontWeight: FontWeight.values.firstWhere(
      (fw) => fw.value == style.fontWeight,
      orElse: () => FontWeight.w700,
    ),
    color: parseHexColor(style.color),
    shadows: shadows,
  );
}

Size measureTextBlockSize({
  required List<String> lines,
  required ResolvedTextStyle style,
  required double canvasWidth,
}) {
  if (lines.isEmpty) return Size.zero;

  final scale = canvasFontScale(canvasWidth);
  final fillStyle = buildCanvasFillTextStyle(style, canvasWidth);
  var maxWidth = 0.0;
  var totalHeight = 0.0;

  for (final line in lines) {
    final painter = TextPainter(
      text: TextSpan(text: line, style: fillStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    maxWidth = math.max(maxWidth, painter.width);
    totalHeight += painter.height;
  }

  final strokePad =
      style.strokeWidth > 0 ? style.strokeWidth * scale * 2 : 0.0;
  var shadowPad = 0.0;
  if (style.shadowEnabled) {
    shadowPad = style.shadowBlur * scale +
        math.max(
          style.shadowOffsetX.abs(),
          style.shadowOffsetY.abs(),
        ) *
            scale;
  }
  final pad = strokePad + shadowPad;
  return Size(maxWidth + pad, totalHeight + pad);
}

/// 퍼센트 좌표 박스를 화면 픽셀 Rect로 변환합니다.
Rect percentBoxScreenRect({
  required double x,
  required double y,
  required double width,
  required double height,
  required double canvasWidth,
  required double canvasHeight,
  String? anchor,
}) {
  final boxW = width / 100 * canvasWidth;
  final boxH = height / 100 * canvasHeight;
  final px = x / 100 * canvasWidth;
  final py = y / 100 * canvasHeight;
  if (isCenterAnchored(anchor)) {
    return Rect.fromCenter(
      center: Offset(px, py),
      width: boxW,
      height: boxH,
    );
  }
  return Rect.fromLTWH(px, py, boxW, boxH);
}

Rect textElementScreenRect({
  required SlideElement element,
  required ResolvedTextStyle style,
  required double canvasWidth,
  required double canvasHeight,
}) {
  if (element.width != null && element.height != null) {
    return percentBoxScreenRect(
      x: element.x,
      y: element.y,
      width: element.width!,
      height: element.height!,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      anchor: element.anchor,
    );
  }

  final lines = element.lines ?? const [''];
  final size = measureTextBlockSize(
    lines: lines,
    style: style,
    canvasWidth: canvasWidth,
  );
  final px = element.x / 100 * canvasWidth;
  final py = element.y / 100 * canvasHeight;
  final width = math.max(size.width, 1.0);
  final height = math.max(size.height, 1.0);
  if (isCenterAnchored(element.anchor)) {
    return Rect.fromCenter(
      center: Offset(px, py),
      width: width,
      height: height,
    );
  }
  return Rect.fromLTWH(px, py, width, height);
}
