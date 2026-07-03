import 'dart:convert';
import 'dart:io';

import '../models/style_file.dart';

class StyleIo {
  StyleFile readFile(String filePath) {
    final content = File(filePath).readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;
    if (json['format'] != StyleFile.format) {
      throw FormatException('Invalid .style format');
    }
    return StyleFile.fromJson(json);
  }

  void writeFile(String filePath, StyleFile style) {
    File(filePath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(style.toJson()),
    );
  }
}
