// .txt → .sub 일괄 변환 (새찬송가 가사 제작용)
//
// 사용법:
//   dart run dev/scripts/txt_to_sub.dart <입력.txt 또는 폴더> [--style 경로.style] [--out 출력폴더]
//
// 예:
//   dart run dev/scripts/txt_to_sub.dart dev/hymns/새찬송가
//   dart run dev/scripts/txt_to_sub.dart dev/hymns/새찬송가/001_만복의_근원_하나님.txt --style dev/hymns/주일예배.style

import 'dart:io';

import 'package:joowon_subtitle/models/style_file.dart';
import 'package:joowon_subtitle/models/sub_file.dart';
import 'package:joowon_subtitle/services/style_io.dart';
import 'package:joowon_subtitle/services/sub_io.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.writeln(_usage);
    exit(args.isEmpty ? 64 : 0);
  }

  final positional = <String>[];
  String? stylePath;
  String? outDir;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--style' && i + 1 < args.length) {
      stylePath = args[++i];
    } else if (arg == '--out' && i + 1 < args.length) {
      outDir = args[++i];
    } else if (arg.startsWith('--')) {
      stderr.writeln('알 수 없는 옵션: $arg');
      stderr.writeln(_usage);
      exit(64);
    } else {
      positional.add(arg);
    }
  }

  if (positional.length != 1) {
    stderr.writeln('입력 경로를 하나만 지정하세요.');
    stderr.writeln(_usage);
    exit(64);
  }

  final inputPath = p.normalize(positional.single);
  final input = FileSystemEntity.typeSync(inputPath);
  if (input == FileSystemEntityType.notFound) {
    stderr.writeln('경로를 찾을 수 없습니다: $inputPath');
    exit(66);
  }

  StyleFile? style;
  if (stylePath != null) {
    style = StyleIo().readFile(p.normalize(stylePath));
  }

  final subIo = SubIo();
  final txtFiles = _collectTxtFiles(inputPath, input);
  if (txtFiles.isEmpty) {
    stderr.writeln('.txt 파일이 없습니다: $inputPath');
    exit(66);
  }

  var converted = 0;
  for (final txtPath in txtFiles) {
    final content = File(txtPath).readAsStringSync();
    final title = titleFromFileName(txtPath);
    var sub = subIo.fromTxt(content: content, title: title, style: style);
    if (style != null) {
      sub = subIo.applyStyleToSub(sub, style);
    }

    final outputPath = _outputPath(
      txtPath: txtPath,
      inputPath: inputPath,
      inputType: input,
      outDir: outDir,
    );
    Directory(p.dirname(outputPath)).createSync(recursive: true);
    subIo.writeFile(outputPath, sub);
    stdout.writeln('✓ $outputPath (${sub.slides.length} slides)');
    converted++;
  }

  stdout.writeln('\n완료: $converted개 .sub 파일 생성');
}

const _usage = '''
.txt → .sub 일괄 변환

사용법:
  dart run dev/scripts/txt_to_sub.dart <입력.txt 또는 폴더> [옵션]

옵션:
  --style <파일.style>   스타일 적용 (기본: 위치만 설정)
  --out <폴더>           출력 폴더 (기본: .txt와 같은 위치)

.txt 작성 규칙:
  - 빈 줄 1줄 = 새 슬라이드
  - 슬라이드당 1~3줄 권장 (2줄이 가장 흔함)
  - 파일명 예: 001_만복의_근원_하나님.txt → 제목 "만복의 근원 하나님"
''';

List<String> _collectTxtFiles(String inputPath, FileSystemEntityType inputType) {
  if (inputType == FileSystemEntityType.file) {
    if (!inputPath.toLowerCase().endsWith('.txt')) {
      stderr.writeln('.txt 파일만 변환할 수 있습니다: $inputPath');
      exit(66);
    }
    return [inputPath];
  }

  final dir = Directory(inputPath);
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => p.extension(f.path).toLowerCase() == '.txt')
      .map((f) => f.path)
      .toList()
    ..sort();
  return files;
}

String titleFromFileName(String filePath) {
  var name = p.basenameWithoutExtension(filePath);
  name = name.replaceFirst(RegExp(r'^\d+[_\-.]'), '');
  return name.replaceAll('_', ' ');
}

String _outputPath({
  required String txtPath,
  required String inputPath,
  required FileSystemEntityType inputType,
  String? outDir,
}) {
  final baseName = '${p.basenameWithoutExtension(txtPath)}.sub';
  if (outDir != null) {
    return p.join(p.normalize(outDir), baseName);
  }
  if (inputType == FileSystemEntityType.directory && outDir == null) {
    return p.setExtension(txtPath, '.sub');
  }
  return p.setExtension(txtPath, '.sub');
}
