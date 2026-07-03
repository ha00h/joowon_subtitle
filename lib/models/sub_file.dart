import 'slide_elements.dart';

class SubFile {
  const SubFile({
    required this.title,
    required this.slides,
    this.version = 2,
  });

  static const format = 'joowon-subtitle';

  final String title;
  final List<Slide> slides;
  final int version;

  factory SubFile.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;

    if (version == 1) {
      return SubFile.fromV1(json);
    }

    final slidesJson = (json['slides'] as List<dynamic>).cast<Map<String, dynamic>>();
    return SubFile(
      title: json['title'] as String,
      version: 2,
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
            x: 50,
            y: 50,
            zIndex: 1,
            lines: lines,
            anchor: 'center',
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
        'slides': slides.map((s) => s.toJson()).toList(),
      };

  SubFile copyWith({String? title, List<Slide>? slides}) {
    return SubFile(
      title: title ?? this.title,
      slides: slides ?? this.slides,
      version: version,
    );
  }
}
