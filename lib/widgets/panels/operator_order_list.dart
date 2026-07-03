import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/order_provider.dart';
import '../../providers/playback_provider.dart';
import '../../services/workspace_scanner.dart';
import 'selectable_item_card.dart';

class OperatorOrderList extends ConsumerWidget {
  const OperatorOrderList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final playback = ref.watch(playbackProvider);
    final order = orderState.activeOrder;

    if (order == null) {
      return const Center(child: Text('순서를 만들거나 선택하세요'));
    }

    if (order.items.isEmpty) {
      return DragTarget<SubFileEntry>(
        onAcceptWithDetails: (details) {
          final e = details.data;
          ref.read(orderProvider.notifier).addItem(e.path, e.title);
        },
        builder: (context, candidate, rejected) {
          return Center(
            child: Text(
              candidate.isNotEmpty ? '여기에 놓기' : '찬양을 길게 눌러 끌어오세요',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          );
        },
      );
    }

    return DragTarget<SubFileEntry>(
      onAcceptWithDetails: (details) {
        final e = details.data;
        ref.read(orderProvider.notifier).addItem(e.path, e.title);
      },
      builder: (context, candidate, rejected) {
        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: order.items.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            ref.read(orderProvider.notifier).reorderItems(oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final item = order.items[index];
            final isActive = orderState.activeItemIndex == index &&
                playback.panelLayout == SlidePanelLayout.orderSequence;
            return SelectableItemCard(
              key: ValueKey('${order.id}-$index-${item.filePath}'),
              selected: isActive,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                title: Text(item.title, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () =>
                      ref.read(orderProvider.notifier).removeItem(index),
                ),
                onTap: () =>
                    ref.read(playbackProvider.notifier).loadOrderItem(index),
              ),
            );
          },
        );
      },
    );
  }
}
