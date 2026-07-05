import 'dart:ui';

/// 컨텍스트 메뉴가 화면 밖으로 나가지 않도록 위치를 보정한다.
class ContextMenuLayout {
  const ContextMenuLayout({
    required this.mainLeft,
    required this.mainTop,
    required this.submenuLeft,
    required this.submenuTop,
    required this.submenuOpensLeft,
  });

  final double mainLeft;
  final double mainTop;
  final double submenuLeft;
  final double submenuTop;
  final bool submenuOpensLeft;

  static ContextMenuLayout resolve({
    required Offset tapPosition,
    required Size viewportSize,
    required double mainMenuWidth,
    required double mainMenuHeight,
    required double submenuWidth,
    required double submenuHeight,
    required double submenuAnchorTop,
    double padding = 8,
  }) {
    final maxMainLeft = viewportSize.width - mainMenuWidth - padding;
    final maxMainTop = viewportSize.height - mainMenuHeight - padding;
    final mainLeft = tapPosition.dx.clamp(padding, maxMainLeft);
    final mainTop = tapPosition.dy.clamp(padding, maxMainTop);

    final submenuRight = mainLeft + mainMenuWidth - 4 + submenuWidth;
    final opensLeft = submenuRight > viewportSize.width - padding;
    final submenuLeft = opensLeft
        ? (mainLeft - submenuWidth + 4).clamp(padding, maxMainLeft)
        : mainLeft + mainMenuWidth - 4;

    final maxSubmenuTop = viewportSize.height - submenuHeight - padding;
    final submenuTop =
        (mainTop + submenuAnchorTop).clamp(padding, maxSubmenuTop);

    return ContextMenuLayout(
      mainLeft: mainLeft,
      mainTop: mainTop,
      submenuLeft: submenuLeft,
      submenuTop: submenuTop,
      submenuOpensLeft: opensLeft,
    );
  }
}
