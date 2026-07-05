import 'package:uuid/uuid.dart';

import '../models/slide_elements.dart';
import '../models/style_file.dart';

const _uuid = Uuid();

/// 슬라이드 본문·절 표기 요소를 스타일 region 기준으로 생성합니다.
List<SlideElement> buildSlideElements({
  required List<String> bodyLines,
  required String? verseLabelText,
  required StyleFile? style,
  bool includeVerseLabel = false,
}) {
  final bodyRegion =
      style?.primaryBodyRegion ?? StyleFile.defaultStyle.primaryBodyRegion;
  final labelRegion = style?.primaryVerseLabelRegion ??
      StyleFile.defaultStyle.primaryVerseLabelRegion;
  final elements = <SlideElement>[];

  if (includeVerseLabel &&
      verseLabelText != null &&
      verseLabelText.isNotEmpty) {
    elements.add(
      SlideElement(
        id: _uuid.v4(),
        type: SlideElementType.verseLabel,
        x: labelRegion.x,
        y: labelRegion.y,
        width: labelRegion.width,
        height: labelRegion.height,
        zIndex: 2,
        lines: [verseLabelText],
        anchor: 'topLeft',
      ),
    );
  }

  elements.add(
    SlideElement(
      id: _uuid.v4(),
      type: SlideElementType.text,
      x: bodyRegion.x,
      y: bodyRegion.y,
      width: bodyRegion.width,
      height: bodyRegion.height,
      zIndex: 1,
      lines: bodyLines,
      anchor: 'topLeft',
    ),
  );

  return elements;
}
