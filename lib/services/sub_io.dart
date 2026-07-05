import 'dart:convert';
import 'dart:io';

import '../models/slide_elements.dart';
import '../models/style_file.dart';
import '../models/sub_file.dart';
import 'hymn_txt_converter.dart';
import 'slide_element_factory.dart';
import 'txt_parser.dart';

bool looksLikeHymnTxt(String content) {
  return RegExp(r'^\(\d+\)', multiLine: true).hasMatch(content) ||
      content.contains('후렴:');
}

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
    bool includeVerseLabel = false,
  }) {
    final slideLines = parseTxtToSlides(content);

    final slides = slideLines
        .map(
          (lines) => Slide(
            elements: buildSlideElements(
              bodyLines: lines,
              verseLabelText: null,
              style: style,
              includeVerseLabel: includeVerseLabel,
            ),
          ),
        )
        .toList();

    var sub = SubFile(title: title, slides: slides);
    if (style != null) {
      sub = applyStyleToSub(sub, style);
    }
    return sub;
  }

  SubFile fromHymnTxt({
    required String content,
    required String title,
    StyleFile? style,
    int linesPerSlide = 2,
    bool includeVerseLabel = true,
    bool onlyFirstVerse = false,
    int? hymnNumber,
  }) {
    final converted = convertHymnTxtToSlides(
      content,
      linesPerSlide: linesPerSlide,
      onlyFirstVerse: onlyFirstVerse,
    );

    final slideStubs = converted
        .map((s) => Slide(elements: const [], tag: s.tag))
        .toList();
    final lastVerseTag = lastVerseStanzaTag(slideStubs);

    String? currentStanzaTag;
    final slides = <Slide>[];
    for (final slide in converted) {
      if (slide.tag != null) currentStanzaTag = slide.tag;
      final stanzaTag = slide.tag ?? currentStanzaTag;

      String? labelText;
      if (stanzaTag != null && !isRefrainTag(stanzaTag)) {
        if (hymnNumber != null) {
          labelText = saechansonggaVerseLabelText(
            hymnNumber: hymnNumber,
            tag: stanzaTag,
            isLastVerse: stanzaTag == lastVerseTag,
          );
        } else {
          final t = verseLabelTextFromTag(stanzaTag);
          labelText = t.isEmpty ? null : t;
        }
      }
      slides.add(
        Slide(
          tag: slide.tag,
          elements: buildSlideElements(
            bodyLines: slide.lines,
            verseLabelText: labelText,
            style: style,
            includeVerseLabel: includeVerseLabel,
          ),
        ),
      );
    }

    var sub = SubFile(
      title: title,
      slides: slides,
      hymnNumber: hymnNumber,
    );
    if (style != null) {
      sub = applyStyleToSub(sub, style);
    }
    return sub;
  }

  SubFile applyStyleToSub(SubFile sub, StyleFile style) {
    final bodyRegion = style.primaryBodyRegion;
    final labelRegion = style.primaryVerseLabelRegion;

    final slides = sub.slides.map((slide) {
      final elements = slide.elements.map((el) {
        if (el.type == SlideElementType.verseLabel) {
          return _applyTextStyleConfig(el, style.verseLabel, labelRegion);
        }
        if (el.type == SlideElementType.text) {
          return _applyTextStyleConfig(el, style.text, bodyRegion);
        }
        return el;
      }).toList();
      return Slide(
        elements: elements,
        tag: slide.tag,
        colorTag: slide.colorTag,
      );
    }).toList();

    return sub.copyWith(slides: slides);
  }
}

SlideElement _applyTextStyleConfig(
  SlideElement el,
  TextStyleConfig text,
  TextRegionConfig region,
) {
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
}
