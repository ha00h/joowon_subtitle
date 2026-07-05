import 'slide_elements.dart';
import 'style_file.dart';

class ResolvedTextStyle {
  const ResolvedTextStyle({
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    required this.textShadow,
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
  final double strokeWidth;
  final String strokeColor;
  final ShadowStyleConfig shadow;
  final String textAlign;

  bool get shadowEnabled => shadow.enabled;
  double get shadowOffsetX => shadow.offsetX;
  double get shadowOffsetY => shadow.offsetY;
  double get shadowBlur => shadow.blur;
  String get shadowColor => shadow.color;
}

class AppTextDefaults {
  const AppTextDefaults();

  String get fontFamily => StyleFile.defaultStyle.text.fontFamily;
  double get fontSize => StyleFile.defaultStyle.text.fontSize;
  int get fontWeight => StyleFile.defaultStyle.text.fontWeight;
  String get color => StyleFile.defaultStyle.text.color;
  String get textShadow => StyleFile.defaultStyle.text.textShadow;
  double get strokeWidth => StyleFile.defaultStyle.text.strokeWidth;
  String get strokeColor => StyleFile.defaultStyle.text.strokeColor;
  ShadowStyleConfig get shadow => StyleFile.defaultStyle.text.shadow;
  String get textAlign => StyleFile.defaultStyle.text.textAlign;
}

class StyleResolver {
  const StyleResolver({
    this.appDefault = const AppTextDefaults(),
    this.styleFile,
  });

  final AppTextDefaults appDefault;
  final StyleFile? styleFile;

  ResolvedTextStyle resolveText(SlideElement element) {
    final base = element.type == SlideElementType.verseLabel
        ? (styleFile?.verseLabel ??
            (styleFile != null
                ? StyleFile.defaultVerseLabelFromBody(styleFile!.text)
                : null))
        : styleFile?.text;
    final shadow = _resolveShadow(element, base);
    return ResolvedTextStyle(
      fontFamily: element.fontFamily ??
          base?.fontFamily ??
          appDefault.fontFamily,
      fontSize:
          element.fontSize ?? base?.fontSize ?? appDefault.fontSize,
      fontWeight: element.fontWeight ??
          base?.fontWeight ??
          appDefault.fontWeight,
      color: element.color ?? base?.color ?? appDefault.color,
      textShadow: shadow.toCssShadow(),
      strokeWidth: element.textStrokeWidth ??
          base?.strokeWidth ??
          appDefault.strokeWidth,
      strokeColor: element.textStrokeColor ??
          base?.strokeColor ??
          appDefault.strokeColor,
      shadow: shadow,
      textAlign:
          element.textAlign ?? base?.textAlign ?? appDefault.textAlign,
    );
  }

  ShadowStyleConfig _resolveShadow(
    SlideElement element,
    TextStyleConfig? base,
  ) {
    final baseShadow = base?.shadow ?? appDefault.shadow;
    final hasOverride = element.shadowEnabled != null ||
        element.shadowOffsetX != null ||
        element.shadowOffsetY != null ||
        element.shadowBlur != null ||
        element.shadowColor != null;
    if (!hasOverride) return baseShadow;
    return ShadowStyleConfig(
      enabled: element.shadowEnabled ?? baseShadow.enabled,
      offsetX: element.shadowOffsetX ?? baseShadow.offsetX,
      offsetY: element.shadowOffsetY ?? baseShadow.offsetY,
      blur: element.shadowBlur ?? baseShadow.blur,
      color: element.shadowColor ?? baseShadow.color,
    );
  }
}
