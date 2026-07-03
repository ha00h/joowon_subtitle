class ShadowStyleConfig {
  const ShadowStyleConfig({
    this.enabled = true,
    this.offsetX = 2,
    this.offsetY = 2,
    this.blur = 8,
    this.color = '#000000CC',
  });

  final bool enabled;
  final double offsetX;
  final double offsetY;
  final double blur;
  final String color;

  factory ShadowStyleConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ShadowStyleConfig();
    return ShadowStyleConfig(
      enabled: json['enabled'] as bool? ?? true,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 2,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 2,
      blur: (json['blur'] as num?)?.toDouble() ?? 8,
      color: json['color'] as String? ?? '#000000CC',
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'offsetX': offsetX,
        'offsetY': offsetY,
        'blur': blur,
        'color': color,
      };

  String toCssShadow() {
    if (!enabled) return 'none';
    final c = color.startsWith('#') ? _hexToRgba(color) : color;
    return '${offsetX}px ${offsetY}px ${blur}px $c';
  }

  ShadowStyleConfig copyWith({
    bool? enabled,
    double? offsetX,
    double? offsetY,
    double? blur,
    String? color,
  }) {
    return ShadowStyleConfig(
      enabled: enabled ?? this.enabled,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      blur: blur ?? this.blur,
      color: color ?? this.color,
    );
  }

  static String _hexToRgba(String hex) {
    var value = hex.replaceFirst('#', '');
    if (value.length == 8) {
      final a = int.parse(value.substring(0, 2), radix: 16) / 255;
      final r = int.parse(value.substring(2, 4), radix: 16);
      final g = int.parse(value.substring(4, 6), radix: 16);
      final b = int.parse(value.substring(6, 8), radix: 16);
      return 'rgba($r,$g,$b,${a.toStringAsFixed(2)})';
    }
    if (value.length == 6) {
      final r = int.parse(value.substring(0, 2), radix: 16);
      final g = int.parse(value.substring(2, 4), radix: 16);
      final b = int.parse(value.substring(4, 6), radix: 16);
      return 'rgba($r,$g,$b,0.8)';
    }
    return hex;
  }
}

class TextRegionConfig {
  const TextRegionConfig({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String id;
  final String label;
  final double x;
  final double y;
  final double width;
  final double height;

  factory TextRegionConfig.fromJson(Map<String, dynamic> json) {
    return TextRegionConfig(
      id: json['id'] as String,
      label: json['label'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  TextRegionConfig copyWith({
    String? id,
    String? label,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return TextRegionConfig(
      id: id ?? this.id,
      label: label ?? this.label,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

class BackgroundConfig {
  const BackgroundConfig({
    this.type = 'black',
    this.color = '#000000',
    this.imageData,
    this.mimeType,
  });

  final String type;
  final String? color;
  final String? imageData;
  final String? mimeType;

  factory BackgroundConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BackgroundConfig();
    return BackgroundConfig(
      type: json['type'] as String? ?? 'black',
      color: json['color'] as String?,
      imageData: json['imageData'] as String?,
      mimeType: json['mimeType'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (color != null) 'color': color,
        if (imageData != null) 'imageData': imageData,
        if (mimeType != null) 'mimeType': mimeType,
      };

  BackgroundConfig copyWith({
    String? type,
    String? color,
    String? imageData,
    String? mimeType,
    bool clearImage = false,
  }) {
    return BackgroundConfig(
      type: type ?? this.type,
      color: color ?? this.color,
      imageData: clearImage ? null : (imageData ?? this.imageData),
      mimeType: clearImage ? null : (mimeType ?? this.mimeType),
    );
  }
}

class TextStyleConfig {
  const TextStyleConfig({
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    required this.textShadow,
    required this.defaultPosition,
    this.strokeWidth = 0,
    this.strokeColor = '#000000',
    this.shadow = const ShadowStyleConfig(),
    this.textAlign = 'center',
  });

  final String fontFamily;
  final double fontSize;
  final int fontWeight;
  final String color;
  final String textShadow;
  final ({double x, double y}) defaultPosition;
  final double strokeWidth;
  final String strokeColor;
  final ShadowStyleConfig shadow;
  final String textAlign;

  factory TextStyleConfig.fromJson(Map<String, dynamic> json) {
    final pos = json['defaultPosition'] as Map<String, dynamic>;
    final shadowJson = json['shadow'] as Map<String, dynamic>?;
    return TextStyleConfig(
      fontFamily: json['fontFamily'] as String,
      fontSize: (json['fontSize'] as num).toDouble(),
      fontWeight: json['fontWeight'] as int,
      color: json['color'] as String,
      textShadow: json['textShadow'] as String? ?? '2px 2px 8px rgba(0,0,0,0.8)',
      defaultPosition: (
        x: (pos['x'] as num).toDouble(),
        y: (pos['y'] as num).toDouble(),
      ),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0,
      strokeColor: json['strokeColor'] as String? ?? '#000000',
      shadow: ShadowStyleConfig.fromJson(shadowJson),
      textAlign: json['textAlign'] as String? ?? 'center',
    );
  }

  Map<String, dynamic> toJson() => {
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'fontWeight': fontWeight,
        'color': color,
        'textShadow': shadow.toCssShadow(),
        'defaultPosition': {
          'x': defaultPosition.x,
          'y': defaultPosition.y,
        },
        'strokeWidth': strokeWidth,
        'strokeColor': strokeColor,
        'shadow': shadow.toJson(),
        'textAlign': textAlign,
      };

  TextStyleConfig copyWith({
    String? fontFamily,
    double? fontSize,
    int? fontWeight,
    String? color,
    String? textShadow,
    ({double x, double y})? defaultPosition,
    double? strokeWidth,
    String? strokeColor,
    ShadowStyleConfig? shadow,
    String? textAlign,
  }) {
    return TextStyleConfig(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      color: color ?? this.color,
      textShadow: textShadow ?? this.textShadow,
      defaultPosition: defaultPosition ?? this.defaultPosition,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeColor: strokeColor ?? this.strokeColor,
      shadow: shadow ?? this.shadow,
      textAlign: textAlign ?? this.textAlign,
    );
  }
}

class StyleFile {
  const StyleFile({
    required this.name,
    required this.text,
    this.backgroundMode = 'black',
    this.background = const BackgroundConfig(),
    this.textRegions = const [],
    this.version = 1,
  });

  static const format = 'joowon-subtitle-style';

  final String name;
  final TextStyleConfig text;
  final String backgroundMode;
  final BackgroundConfig background;
  final List<TextRegionConfig> textRegions;
  final int version;

  factory StyleFile.fromJson(Map<String, dynamic> json) {
    final text = TextStyleConfig.fromJson(json['text'] as Map<String, dynamic>);
    final regionsJson = json['textRegions'] as List<dynamic>?;
    final regions = regionsJson != null
        ? regionsJson
            .cast<Map<String, dynamic>>()
            .map(TextRegionConfig.fromJson)
            .toList()
        : _legacyRegions(text.defaultPosition);

    return StyleFile(
      name: json['name'] as String,
      text: text,
      backgroundMode:
          (json['output'] as Map<String, dynamic>?)?['backgroundMode'] as String? ??
              'black',
      background: BackgroundConfig.fromJson(
        json['background'] as Map<String, dynamic>?,
      ),
      textRegions: regions,
      version: json['version'] as int? ?? 1,
    );
  }

  static List<TextRegionConfig> _legacyRegions(({double x, double y}) pos) {
    return [
      const TextRegionConfig(
        id: 'title',
        label: '제목',
        x: 50,
        y: 22,
        width: 80,
        height: 18,
      ),
      TextRegionConfig(
        id: 'body',
        label: '본문',
        x: pos.x,
        y: pos.y,
        width: 85,
        height: 50,
      ),
    ];
  }

  Map<String, dynamic> toJson() => {
        'format': format,
        'version': version,
        'name': name,
        'text': text.toJson(),
        'background': background.toJson(),
        'textRegions': textRegions.map((e) => e.toJson()).toList(),
        'output': {'backgroundMode': backgroundMode},
      };

  StyleFile copyWith({
    String? name,
    TextStyleConfig? text,
    String? backgroundMode,
    BackgroundConfig? background,
    List<TextRegionConfig>? textRegions,
    int? version,
  }) {
    return StyleFile(
      name: name ?? this.name,
      text: text ?? this.text,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      background: background ?? this.background,
      textRegions: textRegions ?? this.textRegions,
      version: version ?? this.version,
    );
  }

  TextRegionConfig? regionById(String id) {
    for (final region in textRegions) {
      if (region.id == id) return region;
    }
    return null;
  }

  TextRegionConfig get primaryBodyRegion =>
      regionById('body') ??
      (textRegions.isNotEmpty
          ? textRegions.last
          : TextRegionConfig(
              id: 'body',
              label: '본문',
              x: text.defaultPosition.x,
              y: text.defaultPosition.y,
              width: 85,
              height: 50,
            ));

  static StyleFile get defaultStyle => StyleFile(
        name: '기본',
        text: TextStyleConfig(
          fontFamily: 'Noto Sans KR',
          fontSize: 72,
          fontWeight: 700,
          color: '#FFFFFF',
          textShadow: '2px 2px 8px rgba(0,0,0,0.8)',
          defaultPosition: (x: 50, y: 50),
        ),
        textRegions: _legacyRegions((x: 50, y: 55)),
      );
}
