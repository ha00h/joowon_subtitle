import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../models/slide_elements.dart';
import '../models/style_file.dart';
import '../models/sub_file.dart';
import 'txt_parser.dart';

const _uuid = Uuid();

class SubIo {
  SubFile readFile(String filePath) {
    final content = File(filePath).readAsStringSync();
    return readJson(content);
  }

  SubFile readJson(String content) {
    final json = jsonDecode(content) as Map<String, dynamic>;
    if (json['format'] != SubFile.format) {
      throw FormatException('Invalid .sub format: ${json['format']}');
    }
    return SubFile.fromJson(json);
  }

  void writeFile(String filePath, SubFile sub) {
    final file = File(filePath);
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(sub.toJson()),
    );
  }

  SubFile fromTxt({
    required String content,
    required String title,
    StyleFile? style,
  }) {
    final slideLines = parseTxtToSlides(content);
    final region = style?.primaryBodyRegion ??
        StyleFile.defaultStyle.primaryBodyRegion;

    final slides = slideLines.map((lines) {
      return Slide(
        elements: [
          SlideElement(
            id: _uuid.v4(),
            type: SlideElementType.text,
            x: region.x,
            y: region.y,
            width: region.width,
            height: region.height,
            zIndex: 1,
            lines: lines,
            anchor: 'topLeft',
          ),
        ],
      );
    }).toList();

    return SubFile(title: title, slides: slides);
  }
}
