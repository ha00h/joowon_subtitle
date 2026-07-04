import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/utils/natural_compare.dart';

void main() {
  test('naturalCompare orders numeric segments', () {
    expect(naturalCompare('002_a', '010_b'), lessThan(0));
    expect(naturalCompare('010_b', '100_c'), lessThan(0));
    expect(naturalCompare('새찬송가/009', '새찬송가/010'), lessThan(0));
  });
}
