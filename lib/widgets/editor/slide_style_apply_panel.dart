import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/playback_provider.dart';
import '../../providers/style_provider.dart';
import '../../services/style_store.dart';

/// 선택한 슬라이드(또는 전체)에 스타일을 한 번에 적용
class SlideStyleApplyPanel extends ConsumerStatefulWidget {
  const SlideStyleApplyPanel({
    required this.slideIndex,
    required this.onApplied,
    super.key,
  });

  final int slideIndex;
  final VoidCallback onApplied;

  @override
  ConsumerState<SlideStyleApplyPanel> createState() =>
      _SlideStyleApplyPanelState();
}

class _SlideStyleApplyPanelState extends ConsumerState<SlideStyleApplyPanel> {
  StyleEntry? _picked;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(styleProvider).catalog;
    final activePath = ref.watch(styleProvider).activePath;

    if (catalog.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('등록된 스타일이 없습니다'),
      );
    }

    final initial = catalog.firstWhere(
      (e) => e.path == activePath,
      orElse: () => catalog.first,
    );
    final selected = _picked ?? initial;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '스타일 적용',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.slideIndex >= 0
                ? '슬라이드 [${widget.slideIndex + 1}]에 폰트·색·테두리·그림자를 한 번에 반영합니다.'
                : '슬라이드를 선택하세요',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<StyleEntry>(
            key: ValueKey(selected.path),
            initialValue: selected,
            decoration: const InputDecoration(
              labelText: '스타일',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: catalog
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: widget.slideIndex < 0
                ? null
                : (entry) => setState(() => _picked = entry),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: widget.slideIndex < 0
                ? null
                : () {
                    ref.read(playbackProvider.notifier).applyStyleToSlide(
                          selected.style,
                        );
                    widget.onApplied();
                  },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('이 슬라이드에 적용'),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: widget.slideIndex < 0
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('전체 슬라이드에 적용'),
                        content: Text(
                          '「${selected.name}」 스타일을 모든 슬라이드에 적용할까요?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('취소'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('적용'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    if (!context.mounted) return;
                    ref.read(playbackProvider.notifier).applyStyleToSlide(
                          selected.style,
                          allSlides: true,
                        );
                    widget.onApplied();
                  },
            icon: const Icon(Icons.layers_outlined, size: 18),
            label: const Text('모든 슬라이드에 적용'),
          ),
        ],
      ),
    );
  }
}
