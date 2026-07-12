import '../utils/canvas_text_layout.dart';
import 'resolved_text_style.dart';
import 'slide_elements.dart';
import 'style_file.dart';

/// 현재 슬라이드에 보이는 텍스트 모습으로 [base] 스타일을 덮어쓴 [StyleFile]을 만든다.
///
/// - 본문: [preferredElementId]가 text면 그것, 아니면 첫 text 요소
/// - 절 표기: preferred가 verseLabel이면 그것, 아니면 슬라이드의 verseLabel(없을 때 기존 유지)
/// - 이름·배경은 [base] 유지
/// - textRegions: 요소에 명시적 크기가 있을 때만 갱신(center 앵커는 topLeft로 변환).
///   크기 없으면 기존 영역 유지 — center 좌표를 그대로 넣으면 범위가 틀어짐.
StyleFile styleFileFromSlide({
  required StyleFile base,
  required List<SlideElement> elements,
  String? preferredElementId,
}) {
  final resolver = StyleResolver(styleFile: base);

  SlideElement? preferred;
  if (preferredElementId != null) {
    for (final el in elements) {
      if (el.id == preferredElementId) {
        preferred = el;
        break;
      }
    }
  }

  final body = preferred?.type == SlideElementType.text
      ? preferred
      : _firstOfType(elements, SlideElementType.text);
  final verse = preferred?.type == SlideElementType.verseLabel
      ? preferred
      : findVerseLabelElement(elements);

  var text = base.text;
  var verseLabel = base.verseLabel;
  var bodyRegion = base.primaryBodyRegion;
  var labelRegion = base.primaryVerseLabelRegion;

  if (body != null) {
    final resolved = resolver.resolveText(body);
    final mapped = _mapElementToRegion(
      element: body,
      existing: bodyRegion,
      id: 'body',
      label: '본문',
    );
    text = _textStyleFromResolved(
      resolved,
      defaultPosition: (x: mapped.x, y: mapped.y),
    );
    bodyRegion = mapped;
  }

  if (verse != null) {
    final resolved = resolver.resolveText(verse);
    final mapped = _mapElementToRegion(
      element: verse,
      existing: labelRegion,
      id: 'verseLabel',
      label: '절 표기',
    );
    verseLabel = _textStyleFromResolved(
      resolved,
      defaultPosition: (x: mapped.x, y: mapped.y),
    );
    labelRegion = mapped;
  }

  return base.copyWith(
    text: text,
    verseLabel: verseLabel,
    textRegions: [bodyRegion, labelRegion],
  );
}

/// 스타일 영역은 topLeft 기준. 요소에 크기가 없으면 기존 영역을 유지한다.
TextRegionConfig _mapElementToRegion({
  required SlideElement element,
  required TextRegionConfig existing,
  required String id,
  required String label,
}) {
  final width = element.width;
  final height = element.height;
  if (width == null || height == null) {
    return existing;
  }

  var x = element.x;
  var y = element.y;
  if (isCenterAnchored(element.anchor)) {
    x = element.x - width / 2;
    y = element.y - height / 2;
  }

  return TextRegionConfig(
    id: id,
    label: label,
    x: x.clamp(0, 100),
    y: y.clamp(0, 100),
    width: width.clamp(1, 100),
    height: height.clamp(1, 100),
  );
}

TextStyleConfig _textStyleFromResolved(
  ResolvedTextStyle resolved, {
  required ({double x, double y}) defaultPosition,
}) {
  return TextStyleConfig(
    fontFamily: resolved.fontFamily,
    fontSize: resolved.fontSize,
    fontWeight: resolved.fontWeight,
    color: resolved.color,
    textShadow: resolved.textShadow,
    defaultPosition: defaultPosition,
    strokeWidth: resolved.strokeWidth,
    strokeColor: resolved.strokeColor,
    shadow: resolved.shadow,
    textAlign: resolved.textAlign,
  );
}

SlideElement? _firstOfType(List<SlideElement> elements, SlideElementType type) {
  for (final el in elements) {
    if (el.type == type) return el;
  }
  return null;
}
