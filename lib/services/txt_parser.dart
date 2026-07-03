/// .txt → 슬라이드별 가사 줄 목록
/// 빈 줄 1줄 = 새 슬라이드 (MVP §5)
List<List<String>> parseTxtToSlides(String content) {
  final slides = <List<String>>[];
  var current = <String>[];

  for (final rawLine in content.split('\n')) {
    final line = rawLine.trimRight();
    if (line.isEmpty) {
      if (current.isNotEmpty) {
        slides.add(current);
        current = [];
      }
      continue;
    }
    current.add(line);
  }

  if (current.isNotEmpty) {
    slides.add(current);
  }

  return slides;
}
