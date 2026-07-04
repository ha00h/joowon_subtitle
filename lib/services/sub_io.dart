import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../models/slide_elements.dart';
import '../models/style_file.dart';
import '../models/sub_file.dart';
import 'hymn_txt_converter.dart';
import 'txt_parser.dart';

const _uuid = Uuid();

class SubIo {
  SubFile readFile(String filePath) {
    final content = File(filePath).readAsStringSync();
    return readJson(content);
  }

  SubFile readJson(String content) {
    final json = jsonDecode(content) as Map<String, dynamic>;
    if (json['format'] != SubFile.format) {
      throw FormatException('Invalid .sub format: ${json['format']}');
    }
    return SubFile.fromJson(json);
  }

  void writeFile(String filePath, SubFile sub) {
    final file = File(filePath);
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(sub.toJson()),
    );
  }

  SubFile fromTxt({
    required String content,
    required String title,
    StyleFile? style,
  }) {
    final slideLines = parseTxtToSlides(content);
    final region = style?.primaryBodyRegion ??
        StyleFile.defaultStyle.primaryBodyRegion;

    final slides = slideLines.map((lines) {
      return Slide(
        elements: [
          SlideElement(
            id: _uuid.v4(),
            type: SlideElementType.text,
            x: region.x,
            y: region.y,
            width: region.width,
            height: region.height,
            zIndex: 1,
            lines: lines,
            anchor: 'topLeft',
          ),
        ],
      );
    }).toList();

    return SubFile(title: title, slides: slides);
  }

  SubFile fromHymnTxt({
    required String content,
    required String title,
    StyleFile? style,
    int linesPerSlide = 2,
  }) {
    final converted = convertHymnTxtToSlides(
      content,
      linesPerSlide: linesPerSlide,
    );
    final region = style?.primaryBodyRegion ??
        StyleFile.defaultStyle.primaryBodyRegion;

    final slides = converted.map((slide) {
      return Slide(
        tag: slide.tag,
        elements: [
          SlideElement(
            id: _uuid.v4(),
            type: SlideElementType.text,
            x: region.x,
            y: region.y,
            width: region.width,
            height: region.height,
            zIndex: 1,
            lines: slide.lines,
            anchor: 'topLeft',
          ),
        ],
      );
    }).toList();

    var sub = SubFile(title: title, slides: slides);
    if (style != null) {
      sub = applyStyleToSub(sub, style);
    }
    return sub;
  }

  SubFile applyStyleToSub(SubFile sub, StyleFile style) {
    final region = style.primaryBodyRegion;
    final text = style.text;

    final slides = sub.slides.map((slide) {
      final elements = slide.elements.map((el) {
        if (el.type != SlideElementType.text) return el;
        return el.copyWith(
          fontFamily: text.fontFamily,
          fontSize: text.fontSize,
          fontWeight: text.fontWeight,
          color: text.color,
          textStrokeWidth: text.strokeWidth,
          textStrokeColor: text.strokeColor,
          shadowEnabled: text.shadow.enabled,
          shadowOffsetX: text.shadow.offsetX,
          shadowOffsetY: text.shadow.offsetY,
          shadowBlur: text.shadow.blur,
          shadowColor: text.shadow.color,
          textShadow: text.shadow.toCssShadow(),
          textAlign: text.textAlign,
          x: region.x,
          y: region.y,
          width: region.width,
          height: region.height,
          anchor: 'topLeft',
        );
      }).toList();
      return Slide(elements: elements, tag: slide.tag);
    }).toList();

    return sub.copyWith(slides: slides);
  }
}
