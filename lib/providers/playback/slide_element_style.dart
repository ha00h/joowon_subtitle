part of 'playback.dart';

/// 요소에 지정된 텍스트 스타일 override를 제거하고 스타일 기본값을 따르게 함
SlideElement clearTextStyleOverrides(SlideElement el) {
  return SlideElement(
    id: el.id,
    type: el.type,
    x: el.x,
    y: el.y,
    zIndex: el.zIndex,
    lines: el.lines,
    anchor: el.anchor,
  );
}

SlideElement applyStyleConfigToTextElement(
  SlideElement element,
  TextStyleConfig text, {
  required double x,
  required double y,
  double? width,
  double? height,
}) {
  if (!isTextLikeElement(element.type)) return element;
  return element.copyWith(
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
    x: x,
    y: y,
    width: width,
    height: height,
    anchor: 'topLeft',
  );
}
