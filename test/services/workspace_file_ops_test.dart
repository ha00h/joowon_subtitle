import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/services/workspace_file_ops.dart';

void main() {
  group('titleFromSubBaseName', () {
    test('strips hymn number prefix and underscores', () {
      expect(
        titleFromSubBaseName('001_만복의_근원_하나님'),
        '만복의 근원 하나님',
      );
    });

    test('handles plain filename', () {
      expect(titleFromSubBaseName('나의_찬양'), '나의 찬양');
    });

    test('keeps number-only basename', () {
      expect(titleFromSubBaseName('123'), '123');
    });
  });
}
