import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/resolved_text_style.dart';
import '../../models/slide_elements.dart';
import '../../models/style_file.dart';
import '../../providers/playback_provider.dart';
import '../../utils/canvas_text_layout.dart';
import 'canvas_renderer.dart';

class CanvasEditor extends ConsumerStatefulWidget {
  const CanvasEditor({
    super.key,
    required this.elements,
    required this.resolveText,
    this.isBlank = false,
    this.background,
  });

  final List<SlideElement> elements;
  final ResolvedTextStyle Function(SlideElement) resolveText;
  final bool isBlank;
  final BackgroundConfig? background;

  @override
  ConsumerState<CanvasEditor> createState() => _CanvasEditorState();
}

class _CanvasEditorState extends ConsumerState<CanvasEditor> {
  String? _draggingId;
  Offset? _dragStart;
  bool _dragUndoRecorded = false;

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(editorProvider).selectedElementId;
    final playback = ref.read(playbackProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) {
            final hit = _hitTest(details.localPosition, w, h);
            playback.selectElement(hit);
          },
          onDoubleTapDown: (details) {
            final hit = _hitTest(details.localPosition, w, h);
            if (hit == null) return;
            final el = widget.elements.firstWhere((e) => e.id == hit);
            if (el.type == SlideElementType.text ||
                el.type == SlideElementType.verseLabel) {
              _editText(el);
            }
          },
          onPanStart: (details) {
            final hit = _hitTest(details.localPosition, w, h);
            if (hit == null) return;
            _draggingId = hit;
            _dragStart = details.localPosition;
            _dragUndoRecorded = false;
            playback.selectElement(hit);
          },
          onPanUpdate: (details) {
            if (_draggingId == null || _dragStart == null) return;
            final el = widget.elements.firstWhere((e) => e.id == _draggingId);
            final dx = (details.localPosition.dx - _dragStart!.dx) / w * 100;
            final dy = (details.localPosition.dy - _dragStart!.dy) / h * 100;
            playback.moveElement(
              _draggingId!,
              (el.x + dx).clamp(
                kCanvasPercentMin,
                kCanvasPercentMax - (el.width ?? 0),
              ),
              (el.y + dy).clamp(
                kCanvasPercentMin,
                kCanvasPercentMax - (el.height ?? 0),
              ),
              recordUndo: !_dragUndoRecorded,
            );
            _dragUndoRecorded = true;
            _dragStart = details.localPosition;
          },
          onPanEnd: (_) {
            _draggingId = null;
            _dragStart = null;
            _dragUndoRecorded = false;
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CanvasRenderer(
                elements: widget.elements,
                resolveText: widget.resolveText,
                isBlank: widget.isBlank,
                showCheckerboard: widget.background == null,
                background: widget.background,
              ),
              if (!widget.isBlank)
                ...widget.elements.map((el) {
                  if (el.id != selectedId) return const SizedBox.shrink();
                  return _SelectionOverlay(
                    element: el,
                    w: w,
                    h: h,
                    resolveText: widget.resolveText,
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  String? _hitTest(Offset pos, double w, double h) {
    final sorted = [...widget.elements]
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    for (final el in sorted) {
      final cx = el.x / 100 * w;
      final cy = el.y / 100 * h;

      final Rect rect;
      if (isTextLikeElement(el.type)) {
        final style = widget.resolveText(el);
        rect = textElementScreenRect(
          element: el,
          style: style,
          canvasWidth: w,
          canvasHeight: h,
        );
      } else {
        final ew = (el.width ?? 20) / 100 * w;
        final eh = (el.height ?? 10) / 100 * h;
        rect = Rect.fromCenter(center: Offset(cx, cy), width: ew, height: eh);
      }

      if (rect.contains(pos)) return el.id;
    }
    return null;
  }

  Future<void> _editText(SlideElement el) async {
    final controller = TextEditingController(text: el.lines?.join('\n') ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          el.type == SlideElementType.verseLabel ? '절 표기 편집' : '가사 편집',
        ),
        content: TextField(
          controller: controller,
          maxLines: 8,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('적용'),
          ),
        ],
      ),
    );
    if (result != null) {
      final lines = result.split('\n');
      ref.read(playbackProvider.notifier).updateTextLines(el.id, lines);
    }
  }
}

class _SelectionOverlay extends StatelessWidget {
  const _SelectionOverlay({
    required this.element,
    required this.w,
    required this.h,
    required this.resolveText,
  });

  final SlideElement element;
  final double w;
  final double h;
  final ResolvedTextStyle Function(SlideElement) resolveText;

  @override
  Widget build(BuildContext context) {
    final Rect rect;
    if (isTextLikeElement(element.type)) {
      final style = resolveText(element);
      rect = textElementScreenRect(
        element: element,
        style: style,
        canvasWidth: w,
        canvasHeight: h,
      );
    } else {
      final cx = element.x / 100 * w;
      final cy = element.y / 100 * h;
      final ew = (element.width ?? 20) / 100 * w;
      final eh = (element.height ?? 10) / 100 * h;
      rect = Rect.fromCenter(center: Offset(cx, cy), width: ew, height: eh);
    }

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.cyanAccent, width: 2),
          ),
        ),
      ),
    );
  }
}
