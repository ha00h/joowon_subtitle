import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/widgets/panels/operator_keyboard_shortcuts.dart';

void main() {
  test('operatorKeyboardShortcuts maps numpad digits and enter', () {
    expect(
      operatorKeyboardShortcuts[
          const SingleActivator(LogicalKeyboardKey.numpad0)],
      const DigitIntent('0'),
    );
    expect(
      operatorKeyboardShortcuts[
          const SingleActivator(LogicalKeyboardKey.numpad5)],
      const DigitIntent('5'),
    );
    expect(
      operatorKeyboardShortcuts[
          const SingleActivator(LogicalKeyboardKey.numpad9)],
      const DigitIntent('9'),
    );
    expect(
      operatorKeyboardShortcuts[
          const SingleActivator(LogicalKeyboardKey.numpadEnter)],
      const CommitDigitIntent(),
    );
  });
}
