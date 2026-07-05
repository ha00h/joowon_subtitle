// 새찬송가 645장 .txt → .sub 일괄 변환
//
// 사용법:
//   dart run dev/scripts/import_saechansongga.dart --source <txt폴더|zip> [옵션]
//
// 예:
//   dart run dev/scripts/import_saechansongga.dart --source /tmp/saechansongga_import/txt
//   dart run dev/scripts/import_saechansongga.dart --source hymns.zip --style dev/hymns/주일예배.style
//
// 소스 형식: CCM4U 새찬송가 TXT (001.txt ~ 645.txt)

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:joowon_subtitle/services/style_io.dart';
import 'package:joowon_subtitle/services/sub_io.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.writeln(_usage);
    exit(args.isEmpty ? 64 : 0);
  }

  String? sourcePath;
  String? stylePath = 'dev/hymns/주일예배.style';
  String outDir = 'dev/hymns/새찬송가';
  String indexPath = 'dev/data/saechansongga_index.json';
  int linesPerSlide = 2;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--source' when i + 1 < args.length:
        sourcePath = args[++i];
      case '--style' when i + 1 < args.length:
        stylePath = args[++i];
      case '--out' when i + 1 < args.length:
        outDir = args[++i];
      case '--index' when i + 1 < args.length:
        indexPath = args[++i];
      case '--lines-per-slide' when i + 1 < args.length:
        linesPerSlide = int.parse(args[++i]);
      default:
        if (arg.startsWith('--')) {
          stderr.writeln('알 수 없는 옵션: $arg');
          stderr.writeln(_usage);
          exit(64);
        }
    }
  }

  if (sourcePath == null) {
    stderr.writeln('--source 옵션이 필요합니다.');
    stderr.writeln(_usage);
    exit(64);
  }

  final indexFile = File(indexPath);
  if (!indexFile.existsSync()) {
    stderr.writeln('인덱스 파일이 없습니다: $indexPath');
    exit(66);
  }

  final indexJson =
      jsonDecode(indexFile.readAsStringSync()) as Map<String, dynamic>;
  final hymns = (indexJson['hymns'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map((h) => _HymnIndex(
            number: h['number'] as int,
            title: h['title'] as String,
          ))
      .toList();

  final style = stylePath != null ? StyleIo().readFile(stylePath) : null;
  final subIo = SubIo();
  final txtByNumber = await _loadTxtSources(p.normalize(sourcePath));

  Directory(outDir).createSync(recursive: true);

  var converted = 0;
  var missing = <int>[];

  for (final hymn in hymns) {
    final content = txtByNumber[hymn.number];
    if (content == null) {
      missing.add(hymn.number);
      continue;
    }

    final sub = subIo.fromHymnTxt(
      content: content,
      title: hymn.title,
      style: style,
      linesPerSlide: linesPerSlide,
      hymnNumber: hymn.number,
      includeVerseLabel: true,
    );

    final fileName = _outputFileName(hymn.number, hymn.title);
    final outputPath = p.join(outDir, '$fileName.sub');
    subIo.writeFile(outputPath, sub);
    converted++;
  }

  stdout.writeln('완료: $converted개 .sub 생성 → $outDir');
  if (missing.isNotEmpty) {
    stderr.writeln('누락 ${missing.length}곡: ${missing.take(10).join(', ')}'
        '${missing.length > 10 ? '...' : ''}');
    exit(1);
  }
}

const _usage = '''
새찬송가 645장 .txt → .sub 일괄 변환

사용법:
  dart run dev/scripts/import_saechansongga.dart --source <txt폴더|zip> [옵션]

옵션:
  --source <경로>          txt 폴더 또는 zip (001.txt ~ 645.txt)
  --style <파일.style>     스타일 적용 (기본: dev/hymns/주일예배.style 권장)
  --out <폴더>             출력 폴더 (기본: dev/hymns/새찬송가)
  --index <json>           곡 목록 (기본: dev/data/saechansongga_index.json)
  --lines-per-slide <n>    슬라이드당 줄 수 (기본: 2)
''';

class _HymnIndex {
  const _HymnIndex({required this.number, required this.title});

  final int number;
  final String title;
}

Future<Map<int, String>> _loadTxtSources(String sourcePath) async {
  final entityType = FileSystemEntity.typeSync(sourcePath);
  if (entityType == FileSystemEntityType.directory) {
    return _loadTxtDir(Directory(sourcePath));
  }
  if (entityType == FileSystemEntityType.file &&
      sourcePath.toLowerCase().endsWith('.zip')) {
    return _loadTxtZip(sourcePath);
  }

  stderr.writeln('소스는 txt 폴더 또는 .zip 이어야 합니다: $sourcePath');
  exit(66);
}

Future<Map<int, String>> _loadTxtDir(Directory dir) async {
  final result = <int, String>{};
  for (final entity in dir.listSync()) {
    if (entity is! File) continue;
    final number = _numberFromFileName(p.basename(entity.path));
    if (number == null) continue;
    result[number] = await entity.readAsString();
  }
  return result;
}

Future<Map<int, String>> _loadTxtZip(String zipPath) async {
  final bytes = await File(zipPath).readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  final result = <int, String>{};

  for (final file in archive) {
    if (!file.isFile) continue;
    final name = p.basename(file.name);
    if (!name.toLowerCase().endsWith('.txt')) continue;
    final number = _numberFromFileName(name);
    if (number == null) continue;
    result[number] = utf8.decode(file.content as List<int>);
  }

  return result;
}

int? _numberFromFileName(String name) {
  final base = p.basenameWithoutExtension(name);
  final match = RegExp(r'^(\d+)$').firstMatch(base);
  if (match == null) return null;
  return int.parse(match.group(1)!);
}

String _outputFileName(int number, String title) {
  final padded = number.toString().padLeft(3, '0');
  final safeTitle = title
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
      .replaceAll(' ', '_');
  return '${padded}_$safeTitle';
}
