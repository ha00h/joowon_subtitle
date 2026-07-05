import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/resolved_text_style.dart';
import '../../models/slide_elements.dart';
import '../../models/style_file.dart';
import '../../utils/canvas_text_layout.dart';
import '../../utils/color_utils.dart';

class CanvasRenderer extends StatelessWidget {
  const CanvasRenderer({
    super.key,
    required this.elements,
    required this.resolveText,
    this.isBlank = false,
    this.showCheckerboard = false,
    this.background,
  });

  final List<SlideElement> elements;
  final ResolvedTextStyle Function(SlideElement) resolveText;
  final bool isBlank;
  final bool showCheckerboard;
  final BackgroundConfig? background;

  @override
  Widget build(BuildContext context) {
    if (isBlank) {
      return const SizedBox.expand();
    }

    final sorted = [...elements]..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (background != null)
              Positioned.fill(
                child: _BackgroundLayer(background: background!),
              )
            else if (showCheckerboard)
              const _Checkerboard(),
            ...sorted.map((el) => _buildElement(el, w, h)),
          ],
        );
      },
    );
  }

  Widget _buildElement(SlideElement el, double w, double h) {
    switch (el.type) {
      case SlideElementType.text:
      case SlideElementType.verseLabel:
        return _buildText(el, w, h);
      case SlideElementType.image:
        return _buildImage(el, w, h);
      case SlideElementType.shape:
        return _buildShape(el, w, h);
    }
  }

  Widget _buildText(SlideElement el, double w, double h) {
    final style = resolveText(el);
    final align = canvasTextAlign(style.textAlign);
    final boxW = el.width != null ? el.width! / 100 * w : null;
    final boxH = el.height != null ? el.height! / 100 * h : null;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: columnCrossAxisFor(align),
      children: el.lines!
          .map(
            (line) => _StyledTextLine(
              line: line,
              style: style,
              canvasWidth: w,
              textAlign: align,
            ),
          )
          .toList(),
    );

    if (boxW != null) {
      content = SizedBox(width: boxW, child: content);
    }
    if (boxH != null) {
      content = SizedBox(
        width: boxW,
        height: boxH,
        child: Align(
          alignment: Alignment.topCenter,
          child: content,
        ),
      );
    }

    return Positioned(
      left: el.x / 100 * w,
      top: el.y / 100 * h,
      child: FractionalTranslation(
        translation: anchorFractionalTranslation(el.anchor),
        child: content,
      ),
    );
  }

  Widget _buildImage(SlideElement el, double w, double h) {
    Widget child;
    if (el.data != null && el.data!.isNotEmpty) {
      try {
        final bytes = base64Decode(el.data!);
        child = Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image_outlined,
            color: Colors.white38,
          ),
        );
      } catch (_) {
        child = const Icon(Icons.broken_image_outlined, color: Colors.white38);
      }
    } else {
      child = const Center(
        child: Icon(Icons.image_outlined, color: Colors.white38),
      );
    }

    return Positioned(
      left: el.x / 100 * w,
      top: el.y / 100 * h,
      width: (el.width ?? 10) / 100 * w,
      height: (el.height ?? 10) / 100 * h,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: child,
      ),
    );
  }

  Widget _buildShape(SlideElement el, double w, double h) {
    return Positioned(
      left: el.x / 100 * w,
      top: el.y / 100 * h,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: CustomPaint(
          size: Size((el.width ?? 10) / 100 * w, (el.height ?? 10) / 100 * h),
          painter: _ShapePainter(element: el),
        ),
      ),
    );
  }
}

class _StyledTextLine extends StatelessWidget {
  const _StyledTextLine({
    required this.line,
    required this.style,
    required this.canvasWidth,
    required this.textAlign,
  });

  final String line;
  final ResolvedTextStyle style;
  final double canvasWidth;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final scale = canvasFontScale(canvasWidth);
    final base = buildCanvasFillTextStyle(style, canvasWidth).copyWith(
      color: parseHexColor(style.color),
      shadows: style.shadowEnabled
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
          : const <Shadow>[],
    );

    if (style.strokeWidth <= 0) {
      return Text(
        line,
        textAlign: textAlign,
        style: base,
      );
    }

    final strokeWidth = style.strokeWidth * scale;
    final strokeStyle = base.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = parseHexColor(style.strokeColor),
      color: null,
      shadows: const [],
    );
    final fillStyle = base;

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(line, textAlign: textAlign, style: strokeStyle),
        Text(line, textAlign: textAlign, style: fillStyle),
      ],
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({required this.background});

  final BackgroundConfig background;

  @override
  Widget build(BuildContext context) {
    switch (background.type) {
      case 'color':
        return ColoredBox(color: parseHexColor(background.color ?? '#000000'));
      case 'image':
        if (background.imageData != null && background.imageData!.isNotEmpty) {
          try {
            final bytes = base64Decode(background.imageData!);
            return Image.memory(bytes, fit: BoxFit.cover);
          } catch (_) {
            return const ColoredBox(color: Colors.black);
          }
        }
        return const ColoredBox(color: Colors.black);
      case 'black':
      default:
        return const ColoredBox(color: Colors.black);
    }
  }
}

class _Checkerboard extends StatelessWidget {
  const _Checkerboard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CheckerboardPainter(),
      size: Size.infinite,
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tile = 24.0;
    final paintA = Paint()..color = const Color(0xFF2A2A2A);
    final paintB = Paint()..color = const Color(0xFF1A1A1A);
    for (var y = 0.0; y < size.height; y += tile) {
      for (var x = 0.0; x < size.width; x += tile) {
        final isEven =
            ((x / tile).floor() + (y / tile).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tile, tile),
          isEven ? paintA : paintB,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShapePainter extends CustomPainter {
  _ShapePainter({required this.element});

  final SlideElement element;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = element.stroke != null
        ? parseHexColor(element.stroke!)
        : Colors.white70;

    final stroke = Paint()
      ..color = strokeColor
      ..strokeWidth = element.strokeWidth ?? 2
      ..style = PaintingStyle.stroke;

    if (element.fill != null) {
      final fillPaint = Paint()
        ..color = parseHexColor(element.fill!)
        ..style = PaintingStyle.fill;
      switch (element.shapeType) {
        case ShapeType.rect:
          canvas.drawRect(Offset.zero & size, fillPaint);
        case ShapeType.ellipse:
          canvas.drawOval(Offset.zero & size, fillPaint);
        case ShapeType.line:
        case null:
          break;
      }
    }

    switch (element.shapeType) {
      case ShapeType.rect:
        canvas.drawRect(Offset.zero & size, stroke);
      case ShapeType.ellipse:
        canvas.drawOval(Offset.zero & size, stroke);
      case ShapeType.line:
        canvas.drawLine(Offset.zero, Offset(size.width, size.height), stroke);
      case null:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

