enum SlideElementType { text, verseLabel, image, shape }

enum ShapeType { rect, ellipse, line }

/// 슬라이드 구간 태그 (우클릭 메뉴)
const kSlideTags = [
  '1절',
  '2절',
  '3절',
  '후렴구1',
  '후렴구2',
  '반복',
];

/// 슬라이드 그리드 색 태그용 팔레트 (hex)
const kSlideColorTags = [
  ('#FF6B6B', '빨강'),
  ('#FFA500', '주황'),
  ('#FFD700', '금색'),
  ('#2ECC71', '초록'),
  ('#3498DB', '파랑'),
  ('#9B59B6', '보라'),
  ('#FF69B4', '분홍'),
  ('#808080', '회색'),
];

String formatSlideLabel(int slideNumber, String? tag) {
  final base = '[$slideNumber]';
  if (tag != null && tag.isNotEmpty) return '$base $tag';
  return base;
}

/// 슬라이드 tag → 송출 절 표기 텍스트 (일반·레거시)
String verseLabelTextFromTag(String? tag) {
  if (tag == null || tag.isEmpty) return '';
  if (tag.startsWith('후렴')) return '후렴';
  return tag;
}

/// 후렴 구간 태그 여부 (송출 절 표기 생략)
bool isRefrainTag(String? tag) {
  if (tag == null || tag.isEmpty) return false;
  return tag.startsWith('후렴');
}

/// 슬라이드 목록에서 마지막 **절** 태그 (후렴 제외)
String? lastVerseStanzaTag(Iterable<Slide> slides) {
  String? last;
  for (final slide in slides) {
    final tag = slide.tag;
    if (tag != null && tag.isNotEmpty && !isRefrainTag(tag)) {
      last = tag;
    }
  }
  return last;
}

/// 슬라이드 목록에서 마지막 구간 태그 (후렴 포함)
String? lastStanzaTag(Iterable<Slide> slides) {
  String? last;
  for (final slide in slides) {
    if (slide.tag != null && slide.tag!.isNotEmpty) {
      last = slide.tag;
    }
  }
  return last;
}

/// 새찬송가 송출 절 표기: `새찬송가 8장 1절`, 마지막 절은 `… 마지막` 접미
String saechansonggaVerseLabelText({
  required int hymnNumber,
  required String tag,
  required bool isLastVerse,
}) {
  if (isRefrainTag(tag)) return '';
  final base = '새찬송가 $hymnNumber장 $tag';
  if (isLastVerse) return '$base 마지막';
  return base;
}

/// 태그 없는 슬라이드가 속한 절의 구간 태그 (바로 앞 절 시작 슬라이드에서 상속)
String? effectiveStanzaTag(List<Slide> slides, int slideIndex) {
  if (slideIndex < 0 || slideIndex >= slides.length) return null;
  final direct = slides[slideIndex].tag;
  if (direct != null && direct.isNotEmpty) return direct;
  for (var i = slideIndex - 1; i >= 0; i--) {
    final t = slides[i].tag;
    if (t != null && t.isNotEmpty) return t;
  }
  return null;
}

/// 곡 번호·슬라이드 맥락으로 절 표기 텍스트 결정 (후렴은 null, 같은 절 연속 슬라이드 포함)
String? verseLabelTextForSlide({
  required Slide slide,
  required List<Slide> allSlides,
  int? hymnNumber,
  int? slideIndex,
}) {
  final index = slideIndex ?? allSlides.indexOf(slide);
  if (index < 0) return null;
  final tag = effectiveStanzaTag(allSlides, index);
  if (tag == null || isRefrainTag(tag)) return null;
  if (hymnNumber != null) {
    final lastTag = lastVerseStanzaTag(allSlides);
    return saechansonggaVerseLabelText(
      hymnNumber: hymnNumber,
      tag: tag,
      isLastVerse: lastTag != null && tag == lastTag,
    );
  }
  final text = verseLabelTextFromTag(tag);
  return text.isEmpty ? null : text;
}

bool slideHasVerseLabel(List<SlideElement> elements) {
  return elements.any((e) => e.type == SlideElementType.verseLabel);
}

bool isTextLikeElement(SlideElementType type) {
  return type == SlideElementType.text || type == SlideElementType.verseLabel;
}

/// 찬송가 .sub에서 1절 슬라이드만 추출 (이어지는 무태그 슬라이드 포함)
List<Slide> extractFirstVerseSlides(List<Slide> slides) {
  final result = <Slide>[];
  for (final slide in slides) {
    if (slide.tag != null && slide.tag != '1절') break;
    result.add(slide);
  }
  return result;
}

SlideElement? findVerseLabelElement(List<SlideElement> elements) {
  for (final el in elements) {
    if (el.type == SlideElementType.verseLabel) return el;
  }
  return null;
}

class SlideElement {
  const SlideElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.zIndex,
    this.lines,
    this.anchor,
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textShadow,
    this.textAlign,
    this.textStrokeWidth,
    this.textStrokeColor,
    this.shadowEnabled,
    this.shadowOffsetX,
    this.shadowOffsetY,
    this.shadowBlur,
    this.shadowColor,
    this.data,
    this.mimeType,
    this.width,
    this.height,
    this.opacity,
    this.shapeType,
    this.x2,
    this.y2,
    this.fill,
    this.stroke,
    this.strokeWidth,
  });

  final String id;
  final SlideElementType type;
  final double x;
  final double y;
  final int zIndex;

  final List<String>? lines;
  final String? anchor;
  final String? fontFamily;
  final double? fontSize;
  final int? fontWeight;
  final String? color;
  final String? textShadow;
  final String? textAlign;
  final double? textStrokeWidth;
  final String? textStrokeColor;
  final bool? shadowEnabled;
  final double? shadowOffsetX;
  final double? shadowOffsetY;
  final double? shadowBlur;
  final String? shadowColor;

  final String? data;
  final String? mimeType;
  final double? width;
  final double? height;
  final double? opacity;

  final ShapeType? shapeType;
  final double? x2;
  final double? y2;
  final String? fill;
  final String? stroke;
  final double? strokeWidth;

  factory SlideElement.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    return SlideElement(
      id: json['id'] as String,
      type: SlideElementType.values.byName(typeStr),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      zIndex: json['zIndex'] as int? ?? 0,
      lines: (json['lines'] as List<dynamic>?)?.cast<String>(),
      anchor: json['anchor'] as String?,
      fontFamily: json['fontFamily'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      fontWeight: json['fontWeight'] as int?,
      color: json['color'] as String?,
      textShadow: json['textShadow'] as String?,
      textAlign: json['textAlign'] as String?,
      textStrokeWidth: (json['textStrokeWidth'] as num?)?.toDouble(),
      textStrokeColor: json['textStrokeColor'] as String?,
      shadowEnabled: json['shadowEnabled'] as bool?,
      shadowOffsetX: (json['shadowOffsetX'] as num?)?.toDouble(),
      shadowOffsetY: (json['shadowOffsetY'] as num?)?.toDouble(),
      shadowBlur: (json['shadowBlur'] as num?)?.toDouble(),
      shadowColor: json['shadowColor'] as String?,
      data: json['data'] as String?,
      mimeType: json['mimeType'] as String?,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble(),
      shapeType: json['shapeType'] != null
          ? ShapeType.values.byName(json['shapeType'] as String)
          : null,
      x2: (json['x2'] as num?)?.toDouble(),
      y2: (json['y2'] as num?)?.toDouble(),
      fill: json['fill'] as String?,
      stroke: json['stroke'] as String?,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type.name,
      'id': id,
      'x': x,
      'y': y,
      'zIndex': zIndex,
    };
    if (lines != null) json['lines'] = lines;
    if (anchor != null) json['anchor'] = anchor;
    if (fontFamily != null) json['fontFamily'] = fontFamily;
    if (fontSize != null) json['fontSize'] = fontSize;
    if (fontWeight != null) json['fontWeight'] = fontWeight;
    if (color != null) json['color'] = color;
    if (textShadow != null) json['textShadow'] = textShadow;
    if (textAlign != null) json['textAlign'] = textAlign;
    if (textStrokeWidth != null) json['textStrokeWidth'] = textStrokeWidth;
    if (textStrokeColor != null) json['textStrokeColor'] = textStrokeColor;
    if (shadowEnabled != null) json['shadowEnabled'] = shadowEnabled;
    if (shadowOffsetX != null) json['shadowOffsetX'] = shadowOffsetX;
    if (shadowOffsetY != null) json['shadowOffsetY'] = shadowOffsetY;
    if (shadowBlur != null) json['shadowBlur'] = shadowBlur;
    if (shadowColor != null) json['shadowColor'] = shadowColor;
    if (data != null) json['data'] = data;
    if (mimeType != null) json['mimeType'] = mimeType;
    if (width != null) json['width'] = width;
    if (height != null) json['height'] = height;
    if (opacity != null) json['opacity'] = opacity;
    if (shapeType != null) json['shapeType'] = shapeType!.name;
    if (x2 != null) json['x2'] = x2;
    if (y2 != null) json['y2'] = y2;
    if (fill != null) json['fill'] = fill;
    if (stroke != null) json['stroke'] = stroke;
    if (strokeWidth != null) json['strokeWidth'] = strokeWidth;
    return json;
  }

  SlideElement copyWith({
    String? id,
    SlideElementType? type,
    double? x,
    double? y,
    int? zIndex,
    List<String>? lines,
    String? anchor,
    String? fontFamily,
    double? fontSize,
    int? fontWeight,
    String? color,
    String? textShadow,
    String? textAlign,
    double? textStrokeWidth,
    String? textStrokeColor,
    bool? shadowEnabled,
    double? shadowOffsetX,
    double? shadowOffsetY,
    double? shadowBlur,
    String? shadowColor,
    String? data,
    String? mimeType,
    double? width,
    double? height,
    double? opacity,
    ShapeType? shapeType,
    double? x2,
    double? y2,
    String? fill,
    String? stroke,
    double? strokeWidth,
  }) {
    return SlideElement(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      zIndex: zIndex ?? this.zIndex,
      lines: lines ?? this.lines,
      anchor: anchor ?? this.anchor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      color: color ?? this.color,
      textShadow: textShadow ?? this.textShadow,
      textAlign: textAlign ?? this.textAlign,
      textStrokeWidth: textStrokeWidth ?? this.textStrokeWidth,
      textStrokeColor: textStrokeColor ?? this.textStrokeColor,
      shadowEnabled: shadowEnabled ?? this.shadowEnabled,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowColor: shadowColor ?? this.shadowColor,
      data: data ?? this.data,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      opacity: opacity ?? this.opacity,
      shapeType: shapeType ?? this.shapeType,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
      fill: fill ?? this.fill,
      stroke: stroke ?? this.stroke,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

class Slide {
  const Slide({required this.elements, this.tag, this.colorTag});

  final List<SlideElement> elements;
  final String? tag;
  final String? colorTag;

  factory Slide.fromJson(Map<String, dynamic> json) {
    final list = (json['elements'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return Slide(
      elements: list.map(SlideElement.fromJson).toList(),
      tag: json['tag'] as String?,
      colorTag: json['colorTag'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'elements': elements.map((e) => e.toJson()).toList(),
        if (tag != null) 'tag': tag,
        if (colorTag != null) 'colorTag': colorTag,
      };

  Slide copyWith({
    List<SlideElement>? elements,
    String? tag,
    String? colorTag,
    bool clearTag = false,
    bool clearColorTag = false,
  }) {
    return Slide(
      elements: elements ?? this.elements,
      tag: clearTag ? null : (tag ?? this.tag),
      colorTag: clearColorTag ? null : (colorTag ?? this.colorTag),
    );
  }
}
