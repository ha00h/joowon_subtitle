import 'package:flutter/material.dart';

import '../../models/resolved_text_style.dart';
import '../../models/slide_elements.dart';
import '../../models/style_file.dart';
import '../../utils/canvas_text_layout.dart';
import '../canvas/canvas_renderer.dart';
import '../common/aspect_ratio_fhd.dart';

enum _RegionDragMode { none, move, resize }

class StyleRegionCanvas extends StatefulWidget {
  const StyleRegionCanvas({
    required this.style,
    required this.selectedRegionId,
    required this.onRegionChanged,
    required this.onRegionSelected,
    super.key,
  });

  final StyleFile style;
  final String? selectedRegionId;
  final void Function(TextRegionConfig region) onRegionChanged;
  final ValueChanged<String> onRegionSelected;

  @override
  State<StyleRegionCanvas> createState() => _StyleRegionCanvasState();
}

class _StyleRegionCanvasState extends State<StyleRegionCanvas> {
  String? _draggingId;
  Offset? _dragStart;
  TextRegionConfig? _dragRegionStart;
  _RegionDragMode _dragMode = _RegionDragMode.none;

  static const _hitPadding = 8.0;
  static const _resizeHandleSize = 14.0;

  TextRegionConfig _clampRegion(TextRegionConfig region) {
    final x = region.x.clamp(kCanvasPercentMin, kCanvasPercentMax);
    final y = region.y.clamp(kCanvasPercentMin, kCanvasPercentMax);
    final maxWidth = kCanvasPercentMax - x;
    final maxHeight = kCanvasPercentMax - y;
    return region.copyWith(
      x: x,
      y: y,
      width: region.width.clamp(kRegionMinSizePercent, maxWidth),
      height: region.height.clamp(kRegionMinSizePercent, maxHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolver = StyleResolver(styleFile: widget.style);
    final previewElements = widget.style.textRegions
        .map((region) => _previewElement(region))
        .toList();

    return AspectRatio(
      aspectRatio: AspectRatioFhd.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final hit = _hitRegion(details.localPosition, w, h);
              if (hit != null) widget.onRegionSelected(hit);
            },
            onPanStart: (details) {
              final selected = widget.selectedRegionId;
              if (selected != null) {
                final region = widget.style.regionById(selected);
                if (region != null &&
                    _hitResizeHandle(details.localPosition, region, w, h)) {
                  _dragMode = _RegionDragMode.resize;
                  _draggingId = selected;
                  _dragStart = details.localPosition;
                  _dragRegionStart = region;
                  return;
                }
              }

              final hit = _hitRegion(details.localPosition, w, h);
              if (hit == null) return;
              final region = widget.style.regionById(hit)!;
              _dragMode = _RegionDragMode.move;
              _draggingId = hit;
              _dragStart = details.localPosition;
              _dragRegionStart = region;
              widget.onRegionSelected(hit);
            },
            onPanUpdate: (details) {
              if (_draggingId == null ||
                  _dragStart == null ||
                  _dragRegionStart == null) {
                return;
              }

              final dx = (details.localPosition.dx - _dragStart!.dx) / w * 100;
              final dy = (details.localPosition.dy - _dragStart!.dy) / h * 100;

              final updated = switch (_dragMode) {
                _RegionDragMode.move => _dragRegionStart!.copyWith(
                    x: _dragRegionStart!.x + dx,
                    y: _dragRegionStart!.y + dy,
                  ),
                _RegionDragMode.resize => _dragRegionStart!.copyWith(
                    width: _dragRegionStart!.width + dx,
                    height: _dragRegionStart!.height + dy,
                  ),
                _RegionDragMode.none => _dragRegionStart!,
              };

              widget.onRegionChanged(_clampRegion(updated));
            },
            onPanEnd: (_) {
              _draggingId = null;
              _dragStart = null;
              _dragRegionStart = null;
              _dragMode = _RegionDragMode.none;
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                CanvasRenderer(
                  elements: previewElements,
                  resolveText: resolver.resolveText,
                  background: widget.style.background,
                ),
                ...widget.style.textRegions.map((region) {
                  final rect = _regionScreenRect(region, w, h);
                  return _RegionOverlay(
                    region: region,
                    rect: rect,
                    selected: region.id == widget.selectedRegionId,
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  SlideElement _previewElement(TextRegionConfig region) {
    final isLabel = region.id == 'verseLabel';
    return SlideElement(
      id: region.id,
      type: isLabel ? SlideElementType.verseLabel : SlideElementType.text,
      x: region.x,
      y: region.y,
      width: region.width,
      height: region.height,
      zIndex: isLabel ? 2 : 1,
      lines: isLabel ? const ['새찬송가 8장 1절'] : const ['본문 영역', '가사 미리보기'],
      anchor: 'topLeft',
    );
  }

  Rect _regionScreenRect(TextRegionConfig region, double w, double h) {
    return percentBoxScreenRect(
      x: region.x,
      y: region.y,
      width: region.width,
      height: region.height,
      canvasWidth: w,
      canvasHeight: h,
      anchor: 'topLeft',
    );
  }

  bool _hitResizeHandle(
    Offset pos,
    TextRegionConfig region,
    double w,
    double h,
  ) {
    final rect = _regionScreenRect(region, w, h);
    final handle = Rect.fromCenter(
      center: rect.bottomRight,
      width: _resizeHandleSize,
      height: _resizeHandleSize,
    );
    return handle.contains(pos);
  }

  String? _hitRegion(Offset pos, double w, double h) {
    for (final region in widget.style.textRegions.reversed) {
      final rect = _regionScreenRect(region, w, h).inflate(_hitPadding);
      if (rect.contains(pos)) return region.id;
    }
    return null;
  }
}

class _RegionOverlay extends StatelessWidget {
  const _RegionOverlay({
    required this.region,
    required this.rect,
    required this.selected,
  });

  final TextRegionConfig region;
  final Rect rect;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? Colors.cyanAccent : Colors.white38;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: borderColor,
                  width: selected ? 2 : 1,
                ),
                color: selected
                    ? Colors.cyanAccent.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
        ),
        Positioned(
          left: rect.left,
          top: rect.top - 18,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? Colors.cyanAccent.withValues(alpha: 0.9)
                    : Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  region.label,
                  style: TextStyle(
                    color: selected ? Colors.black87 : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (selected)
          Positioned(
            left: rect.right - 7,
            top: rect.bottom - 7,
            child: IgnorePointer(
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.black87, width: 1),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
