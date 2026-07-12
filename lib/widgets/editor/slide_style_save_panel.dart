import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/slide_elements.dart';
import '../../models/style_from_slide.dart';
import '../../providers/output_window_provider.dart';
import '../../providers/playback_provider.dart';
import '../../providers/style_provider.dart';

/// 현재 편집 화면을 활성 스타일 파일에 덮어쓴다.
class SlideStyleSavePanel extends ConsumerWidget {
  const SlideStyleSavePanel({
    required this.slideIndex,
    required this.onSaved,
    super.key,
  });

  final int slideIndex;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePath = ref.watch(styleProvider).activePath;
    final styleName = ref.watch(activeStyleFileProvider).name;
    final enabled = slideIndex >= 0 && activePath != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '스타일에 저장',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            activePath == null
                ? '활성 스타일이 없습니다'
                : '현재 화면의 폰트·색·위치 등을 「$styleName」에 덮어씁니다.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: !enabled
                ? null
                : () => _confirmAndSave(
                      context: context,
                      ref: ref,
                      styleName: styleName,
                      path: activePath,
                    ),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('현재 화면을 스타일에 저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSave({
    required BuildContext context,
    required WidgetRef ref,
    required String styleName,
    required String path,
  }) async {
    var clearOverrides = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('스타일에 저장'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('「$styleName」 스타일을 현재 화면으로 덮어쓸까요?'),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: clearOverrides,
                    onChanged: (v) =>
                        setLocal(() => clearOverrides = v ?? true),
                    title: const Text('저장 후 이 슬라이드 개별 스타일 제거'),
                    subtitle: const Text('이후부터 스타일 기본값을 따릅니다'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;
    if (!context.mounted) return;

    final playback = ref.read(playbackProvider);
    final sub = playback.currentSub;
    if (sub == null ||
        slideIndex < 0 ||
        slideIndex >= sub.slides.length) {
      return;
    }

    final slide = sub.slides[slideIndex];
    final hasTextLike = slide.elements.any((e) => isTextLikeElement(e.type));
    if (!hasTextLike) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 텍스트 요소가 없습니다')),
      );
      return;
    }

    final base = ref.read(activeStyleFileProvider);
    final selectedId = ref.read(editorProvider).selectedElementId;
    final updated = styleFileFromSlide(
      base: base,
      elements: slide.elements,
      preferredElementId: selectedId,
    );

    await ref.read(styleProvider.notifier).saveStyle(path, updated);
    if (clearOverrides) {
      ref.read(playbackProvider.notifier).clearSlideTextStyleOverrides();
    }
    ref.read(outputWindowProvider.notifier).syncPlaybackIfOpen();
    onSaved();
  }
}
