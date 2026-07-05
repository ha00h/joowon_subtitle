// ignore_for_file: avoid_print

import 'dart:io';

import 'package:joowon_subtitle/models/slide_elements.dart';
import 'package:joowon_subtitle/services/slide_element_factory.dart';
import 'package:joowon_subtitle/services/style_io.dart';
import 'package:joowon_subtitle/services/sub_io.dart';

/// 기존 찬송가 .sub에서 1절만 추출하고 verseLabel을 붙여 미리보기용 파일 생성
void main(List<String> args) {
  final sourcePath = args.isNotEmpty
      ? args[0]
      : 'dev/hymns/새찬송가/008_거룩_거룩_거룩.sub';
  final outPath = args.length > 1 ? args[1] : 'dev/hymns/008_거룩_1절만.sub';
  final stylePath =
      args.length > 2 ? args[2] : 'dev/hymns/주일예배.style';

  final subIo = SubIo();
  final style = StyleIo().readFile(stylePath);
  final full = subIo.readFile(sourcePath);
  final firstVerse = extractFirstVerseSlides(full.slides);
  if (firstVerse.isEmpty) {
    stderr.writeln('1절 슬라이드를 찾지 못했습니다: $sourcePath');
    exit(1);
  }

  final slides = <Slide>[];
  for (var i = 0; i < firstVerse.length; i++) {
    final slide = firstVerse[i];
    final body = slide.elements
        .where((e) => e.type == SlideElementType.text)
        .toList();
    final bodyLines = body.isNotEmpty
        ? (body.first.lines ?? const <String>[])
        : const <String>[];

    final labelText = verseLabelTextForSlide(
      slide: slide,
      allSlides: firstVerse,
      hymnNumber: full.hymnNumber ?? _hymnNumberFromPath(sourcePath),
      slideIndex: i,
    );

    final elements = buildSlideElements(
      bodyLines: bodyLines,
      verseLabelText: labelText,
      style: style,
      includeVerseLabel: labelText != null,
    );

    final styled = elements.map((el) {
      if (el.type == SlideElementType.text && body.isNotEmpty) {
        final src = body.first;
        return el.copyWith(
          id: src.id,
          x: src.x,
          y: src.y,
          width: src.width,
          height: src.height,
          fontFamily: src.fontFamily,
          fontSize: src.fontSize,
          fontWeight: src.fontWeight,
          color: src.color,
          textAlign: src.textAlign,
          textStrokeWidth: src.textStrokeWidth,
          textStrokeColor: src.textStrokeColor,
          shadowEnabled: src.shadowEnabled,
          shadowOffsetX: src.shadowOffsetX,
          shadowOffsetY: src.shadowOffsetY,
          shadowBlur: src.shadowBlur,
          shadowColor: src.shadowColor,
          textShadow: src.textShadow,
        );
      }
      return el;
    }).toList();

    slides.add(
      Slide(
        elements: styled,
        tag: slide.tag,
        colorTag: slide.colorTag,
      ),
    );
  }

  var sub = full.copyWith(
    title: '${full.title} (1절)',
    slides: slides,
  );
  sub = subIo.applyStyleToSub(sub, style);
  subIo.writeFile(outPath, sub);
  print('Wrote ${slides.length} slides → $outPath');
}

int? _hymnNumberFromPath(String path) {
  final base = path.split('/').last.replaceAll('.sub', '');
  final match = RegExp(r'^(\d+)_').firstMatch(base);
  if (match == null) return null;
  return int.parse(match.group(1)!);
}
