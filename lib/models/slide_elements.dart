enum SlideElementType { text, image, shape }

enum ShapeType { rect, ellipse, line }

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
  const Slide({required this.elements});

  final List<SlideElement> elements;

  factory Slide.fromJson(Map<String, dynamic> json) {
    final list = (json['elements'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return Slide(
      elements: list.map(SlideElement.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'elements': elements.map((e) => e.toJson()).toList(),
      };
}
