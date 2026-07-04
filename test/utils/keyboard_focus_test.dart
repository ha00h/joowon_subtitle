import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/utils/keyboard_focus.dart';

void main() {
  test('isTextInputFocused is false without focus', () {
    expect(isTextInputFocused(), isFalse);
  });
}
