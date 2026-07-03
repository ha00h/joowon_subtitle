import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/operator_ui_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/output_window_provider.dart';
import '../../providers/playback_provider.dart';

class OperatorStatusBar extends ConsumerWidget {
  const OperatorStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final orderState = ref.watch(orderProvider);
    final outputWindow = ref.watch(outputWindowProvider);
    final ui = ref.watch(operatorUiProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);
    final uiNotifier = ref.read(operatorUiProvider.notifier);

    final hasSub = playback.currentSub != null;
    final hasOrder = orderState.activeOrder != null;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _StatusChip(
                  label: outputWindow.isReconnecting
                      ? '재연결…'
                      : outputWindow.isOpen
                          ? '송출 ON'
                          : '송출 OFF',
                  icon: outputWindow.isOpen
                      ? Icons.cast_connected
                      : Icons.cast,
                  active: outputWindow.isOpen,
                ),
                const SizedBox(width: 6),
                _StatusChip(
                  label: 'black',
                  icon: Icons.brightness_2,
                  active: playback.isBlack,
                ),
                const SizedBox(width: 6),
                _StatusChip(
                  label: 'still',
                  icon: Icons.layers,
                  active: playback.isStill,
                ),
                const SizedBox(width: 16),
                IconButton(
                  tooltip: '이전 곡',
                  onPressed: !hasOrder
                      ? null
                      : () => playbackNotifier.previousHymn(),
                  icon: const Icon(Icons.first_page),
                ),
                IconButton(
                  tooltip: '이전 슬라이드 (←)',
                  onPressed: !hasSub
                      ? null
                      : () => playbackNotifier.previousSlide(),
                  icon: const Icon(Icons.skip_previous),
                ),
                IconButton(
                  tooltip: '다음 슬라이드 (→)',
                  onPressed: !hasSub
                      ? null
                      : () => playbackNotifier.nextSlide(),
                  icon: const Icon(Icons.skip_next),
                ),
                IconButton(
                  tooltip: '다음 곡',
                  onPressed: !hasOrder
                      ? null
                      : () => playbackNotifier.nextHymn(),
                  icon: const Icon(Icons.last_page),
                ),
                if (hasSub) ...[
                  const SizedBox(width: 8),
                  Text(
                    playback.slideIndex >= 0
                        ? '${playback.slideIndex + 1} / ${playback.currentSub!.slides.length}'
                        : '— / ${playback.currentSub!.slides.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const Spacer(),
                Icon(
                  Icons.grid_view,
                  size: 18,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '${OperatorUiState.minGridColumns}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(
                  width: 120,
                  child: Slider(
                    value: ui.gridColumns.toDouble(),
                    min: OperatorUiState.minGridColumns.toDouble(),
                    max: OperatorUiState.maxGridColumns.toDouble(),
                    divisions: OperatorUiState.maxGridColumns -
                        OperatorUiState.minGridColumns,
                    label: '${ui.gridColumns}열',
                    onChanged: (v) => uiNotifier.setGridColumns(v.round()),
                  ),
                ),
                Text(
                  '${OperatorUiState.maxGridColumns}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.active,
  });

  final String label;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? colorScheme.primaryContainer.withValues(alpha: 0.6)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: active
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}
