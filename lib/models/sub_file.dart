import 'slide_elements.dart';

class SubFile {
  const SubFile({
    required this.title,
    required this.slides,
    this.version = 2,
    this.hymnNumber,
  });

  static const format = 'joowon-subtitle';

  final String title;
  final List<Slide> slides;
  final int version;
  /// 새찬송가 곡 번호 (절 표기 `N장 M절`용)
  final int? hymnNumber;

  factory SubFile.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;

    if (version == 1) {
      return SubFile.fromV1(json);
    }

    final slidesJson = (json['slides'] as List<dynamic>).cast<Map<String, dynamic>>();
    return SubFile(
      title: json['title'] as String,
      version: 2,
      hymnNumber: json['hymnNumber'] as int?,
      slides: slidesJson.map(Slide.fromJson).toList(),
    );
  }

  factory SubFile.fromV1(Map<String, dynamic> json) {
    final slidesRaw = (json['slides'] as List<dynamic>).cast<Map<String, dynamic>>();
    final slides = slidesRaw.map((slideJson) {
      if (slideJson.containsKey('elements')) {
        return Slide.fromJson(slideJson);
      }
      final lines = (slideJson['lines'] as List<dynamic>).cast<String>();
      return Slide(
        elements: [
          SlideElement(
            id: 'text-${lines.first.hashCode}',
            type: SlideElementType.text,
            x: 8,
            y: 10,
            zIndex: 1,
            lines: lines,
            anchor: 'topLeft',
          ),
        ],
      );
    }).toList();

    return SubFile(title: json['title'] as String, slides: slides, version: 2);
  }

  Map<String, dynamic> toJson() => {
        'format': format,
        'version': version,
        'title': title,
        if (hymnNumber != null) 'hymnNumber': hymnNumber,
        'slides': slides.map((s) => s.toJson()).toList(),
      };

  SubFile copyWith({
    String? title,
    List<Slide>? slides,
    int? hymnNumber,
    bool clearHymnNumber = false,
  }) {
    return SubFile(
      title: title ?? this.title,
      slides: slides ?? this.slides,
      version: version,
      hymnNumber: clearHymnNumber ? null : (hymnNumber ?? this.hymnNumber),
    );
  }
}
