import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 패널 가로·세로 크기 조절 드래그 핸들
class PanelResizeHandle extends StatelessWidget {
  const PanelResizeHandle({
    required this.axis,
    required this.onDelta,
    this.onDragEnd,
    super.key,
  });

  final Axis axis;
  final ValueChanged<double> onDelta;
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = axis == Axis.horizontal;
    return MouseRegion(
      cursor: isHorizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate:
            isHorizontal ? (details) => onDelta(details.delta.dx) : null,
        onHorizontalDragEnd: isHorizontal ? (_) => onDragEnd?.call() : null,
        onVerticalDragUpdate:
            isHorizontal ? null : (details) => onDelta(details.delta.dy),
        onVerticalDragEnd: isHorizontal ? null : (_) => onDragEnd?.call(),
        child: Container(
          width: isHorizontal ? 6 : double.infinity,
          height: isHorizontal ? double.infinity : 6,
          alignment: Alignment.center,
          child: Container(
            width: isHorizontal ? 2 : 32,
            height: isHorizontal ? 32 : 2,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
