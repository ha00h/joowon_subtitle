import 'package:flutter/material.dart';

/// 스크롤바 thumb를 항상 표시하는 ScrollBehavior
class AlwaysVisibleScrollbarBehavior extends MaterialScrollBehavior {
  const AlwaysVisibleScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      child: child,
    );
  }
}
