import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/utils/context_menu_layout.dart';

void main() {
  group('ContextMenuLayout', () {
    test('keeps main menu inside viewport', () {
      final layout = ContextMenuLayout.resolve(
        tapPosition: const Offset(1900, 1050),
        viewportSize: const Size(1920, 1080),
        mainMenuWidth: 168,
        mainMenuHeight: 144,
        submenuWidth: 120,
        submenuHeight: 253,
        submenuAnchorTop: 108,
      );

      expect(layout.mainLeft, lessThanOrEqualTo(1920 - 168 - 8));
      expect(layout.mainTop, lessThanOrEqualTo(1080 - 144 - 8));
    });

    test('opens submenu to the left when right edge overflows', () {
      final layout = ContextMenuLayout.resolve(
        tapPosition: const Offset(1800, 400),
        viewportSize: const Size(1920, 1080),
        mainMenuWidth: 168,
        mainMenuHeight: 144,
        submenuWidth: 120,
        submenuHeight: 253,
        submenuAnchorTop: 108,
      );

      expect(layout.submenuOpensLeft, isTrue);
      expect(layout.submenuLeft, lessThan(layout.mainLeft));
    });
  });
}
