import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_fonts.dart';
import '../../models/resolved_text_style.dart';
import '../../models/slide_elements.dart';
import '../../providers/playback_provider.dart';
import '../../providers/style_provider.dart';
import '../common/color_picker_row.dart';

class StylePanel extends ConsumerWidget {
  const StylePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final playback = ref.watch(playbackProvider);
    final styleFile = ref.watch(activeStyleFileProvider);
    final activeName = ref.watch(styleProvider).style.name;

    final sub = playback.currentSub;
    if (sub == null) {
      return const Center(child: Text('곡을 선택하세요'));
    }

    final slide = sub.slides.isEmpty || playback.slideIndex < 0
        ? null
        : sub.slides[playback.slideIndex.clamp(0, sub.slides.length - 1)];

    SlideElement? selected;
    if (editor.selectedElementId != null && slide != null) {
      for (final el in slide.elements) {
        if (el.id == editor.selectedElementId) {
          selected = el;
          break;
        }
      }
    }

    final resolver = StyleResolver(styleFile: styleFile);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('스타일', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '적용 중: $activeName',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(),
          if (selected == null)
            const Text('요소를 선택하세요', style: TextStyle(color: Colors.white54))
          else if (selected.type == SlideElementType.text) ...[
            _TextStyleControls(element: selected, resolver: resolver),
          ] else ...[
            Text('선택: ${selected.type.name}'),
            const SizedBox(height: 8),
            Text(
              '위치: ${selected.x.toStringAsFixed(1)}%, '
              '${selected.y.toStringAsFixed(1)}%',
            ),
          ],
          const Divider(),
          const Text('요소 추가', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _toolBtn(Icons.text_fields, '텍스트', () {
                ref.read(playbackProvider.notifier).addTextElement();
              }),
              _toolBtn(Icons.crop_square, '사각', () {
                ref.read(playbackProvider.notifier).addShape(ShapeType.rect);
              }),
              _toolBtn(Icons.circle_outlined, '타원', () {
                ref.read(playbackProvider.notifier).addShape(ShapeType.ellipse);
              }),
              _toolBtn(Icons.remove, '선', () {
                ref.read(playbackProvider.notifier).addShape(ShapeType.line);
              }),
              _toolBtn(Icons.image_outlined, '이미지', () {
                ref.read(playbackProvider.notifier).addImageFromFile();
              }),
            ],
          ),
          if (selected != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(playbackProvider.notifier).deleteSelectedElement(),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('선택 요소 삭제'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        visualDensity: VisualDensity.compact,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

class _TextStyleControls extends ConsumerWidget {
  const _TextStyleControls({
    required this.element,
    required this.resolver,
  });

  final SlideElement element;
  final StyleResolver resolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = resolver.resolveText(element);
    final playback = ref.read(playbackProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('텍스트 스타일', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: AppFonts.options
              .map((e) => e.$1)
              .contains(resolved.fontFamily)
              ? resolved.fontFamily
              : AppFonts.defaultFamily,
          decoration: const InputDecoration(
            labelText: '폰트',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: AppFonts.options
              .map(
                (f) => DropdownMenuItem(value: f.$1, child: Text(f.$2)),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            playback.updateElement(applyFontOverride(element, v));
          },
        ),
        const SizedBox(height: 8),
        Text('크기: ${resolved.fontSize.toInt()}'),
        Slider(
          value: resolved.fontSize.clamp(24, 120),
          min: 24,
          max: 120,
          divisions: 48,
          label: resolved.fontSize.toInt().toString(),
          onChanged: (v) {
            playback.updateElement(applyFontSizeOverride(element, v));
          },
        ),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 400, label: Text('보통')),
            ButtonSegment(value: 700, label: Text('굵게')),
          ],
          selected: {resolved.fontWeight >= 700 ? 700 : 400},
          onSelectionChanged: (s) {
            playback.updateElement(
              applyFontWeightOverride(element, s.first),
            );
          },
        ),
        const SizedBox(height: 8),
        ColorPickerRow(
          label: '폰트 색',
          color: resolved.color,
          onChanged: (hex) {
            playback.updateElement(applyColorOverride(element, hex));
          },
        ),
      ],
    );
  }
}
