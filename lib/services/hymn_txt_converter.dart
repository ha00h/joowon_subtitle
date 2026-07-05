/// CCM4U 등 새찬송가 .txt 형식 → 슬라이드별 가사 줄 목록
///
/// - 빈 줄: 절(구간) 경계
/// - 구간 안에서는 [linesPerSlide]줄씩 한 슬라이드
/// - (1), (2), 후렴: 등의 표식은 가사에서 제거하고 [SlideTag]로 반환
List<ConvertedSlide> convertHymnTxtToSlides(
  String content, {
  int linesPerSlide = 2,
  bool onlyFirstVerse = false,
}) {
  if (linesPerSlide < 1) {
    throw ArgumentError.value(linesPerSlide, 'linesPerSlide', 'must be >= 1');
  }

  final slides = <ConvertedSlide>[];
  var stanzaLines = <String>[];
  String? stanzaTag;
  var stanzaCount = 0;

  void flushStanza() {
    if (stanzaLines.isEmpty) return;

    for (var i = 0; i < stanzaLines.length; i += linesPerSlide) {
      final end = (i + linesPerSlide).clamp(0, stanzaLines.length);
      final chunk = stanzaLines.sublist(i, end);
      final tag = i == 0 ? stanzaTag : null;
      slides.add(ConvertedSlide(lines: chunk, tag: tag));
    }

    stanzaLines = [];
    stanzaTag = null;
    stanzaCount++;
  }

  for (final rawLine in content.split('\n')) {
    if (onlyFirstVerse && stanzaCount >= 1) break;

    final trimmed = rawLine.trimRight();
    if (trimmed.isEmpty) {
      flushStanza();
      if (onlyFirstVerse && stanzaCount >= 1) break;
      continue;
    }

    final parsed = _parseLyricLine(trimmed);
    if (stanzaLines.isEmpty && parsed.tag != null) {
      stanzaTag = parsed.tag;
    }
    stanzaLines.add(parsed.text);
  }

  if (!onlyFirstVerse || stanzaCount < 1) {
    flushStanza();
  }
  return slides;
}

class ConvertedSlide {
  const ConvertedSlide({required this.lines, this.tag});

  final List<String> lines;
  final String? tag;
}

class _ParsedLine {
  const _ParsedLine({required this.text, this.tag});

  final String text;
  final String? tag;
}

_ParsedLine _parseLyricLine(String line) {
  final verseMatch = RegExp(r'^\((\d+)\)\s*').firstMatch(line);
  if (verseMatch != null) {
    final n = int.parse(verseMatch.group(1)!);
    return _ParsedLine(
      text: line.substring(verseMatch.end).trim(),
      tag: '$n절',
    );
  }

  final refrainMatch = RegExp(r'^후렴:\s*').firstMatch(line);
  if (refrainMatch != null) {
    return _ParsedLine(
      text: line.substring(refrainMatch.end).trim(),
      tag: '후렴구1',
    );
  }

  return _ParsedLine(text: line.trim());
}
