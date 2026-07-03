import '../models/style_file.dart';
import '../models/sub_file.dart';

class PlaybackSyncPayload {
  PlaybackSyncPayload({
    this.sub,
    this.slideIndex = 0,
    this.isBlank = false,
    StyleFile? style,
    this.outputBackground = 'black',
  }) : style = style ?? StyleFile.defaultStyle;

  final SubFile? sub;
  final int slideIndex;
  final bool isBlank;
  final StyleFile style;
  final String outputBackground;

  Map<String, dynamic> toJson() => {
        'slideIndex': slideIndex,
        'isBlank': isBlank,
        'outputBackground': outputBackground,
        'style': style.toJson(),
        if (sub != null) 'sub': sub!.toJson(),
      };

  PlaybackSyncPayload copyWith({
    SubFile? sub,
    int? slideIndex,
    bool? isBlank,
    StyleFile? style,
    String? outputBackground,
  }) {
    return PlaybackSyncPayload(
      sub: sub ?? this.sub,
      slideIndex: slideIndex ?? this.slideIndex,
      isBlank: isBlank ?? this.isBlank,
      style: style ?? this.style,
      outputBackground: outputBackground ?? this.outputBackground,
    );
  }

  factory PlaybackSyncPayload.fromJson(Map<String, dynamic> json) {
    return PlaybackSyncPayload(
      sub: json['sub'] != null
          ? SubFile.fromJson(json['sub'] as Map<String, dynamic>)
          : null,
      slideIndex: json['slideIndex'] as int? ?? 0,
      isBlank: json['isBlank'] as bool? ?? false,
      style: json['style'] != null
          ? StyleFile.fromJson(json['style'] as Map<String, dynamic>)
          : StyleFile.defaultStyle,
      outputBackground: json['outputBackground'] as String? ?? 'black',
    );
  }
}
