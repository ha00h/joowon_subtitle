/// 경로·파일명에 포함된 숫자를 자연스럽게 비교 (001 < 010 < 100)
int naturalCompare(String a, String b) {
  final re = RegExp(r'(\d+|\D+)');
  final ta = re.allMatches(a).map((m) => m.group(0)!).toList();
  final tb = re.allMatches(b).map((m) => m.group(0)!).toList();
  final len = ta.length < tb.length ? ta.length : tb.length;

  for (var i = 0; i < len; i++) {
    final sa = ta[i];
    final sb = tb[i];
    final na = int.tryParse(sa);
    final nb = int.tryParse(sb);
    if (na != null && nb != null) {
      final c = na.compareTo(nb);
      if (c != 0) return c;
    } else {
      final c = sa.compareTo(sb);
      if (c != 0) return c;
    }
  }

  return ta.length.compareTo(tb.length);
}
