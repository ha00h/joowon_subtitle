import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/order_provider.dart';
import '../../providers/playback_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../services/workspace_scanner.dart';
import '../common/always_visible_scrollbar.dart';
import 'operator_order_list.dart';
import 'operator_search_field.dart';
import 'selectable_item_card.dart';

class OperatorSearchPanel extends ConsumerWidget {
  const OperatorSearchPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final orderState = ref.watch(orderProvider);
    final playback = ref.watch(playbackProvider);

    return ScrollConfiguration(
      behavior: const AlwaysVisibleScrollbarBehavior(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: OperatorSearchField(
              initialValue: workspace.query,
              onChanged: ref.read(workspaceProvider.notifier).setQuery,
            ),
          ),
          if (workspace.rootPath != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                workspace.query.trim().isEmpty
                    ? '찬양 ${workspace.entries.length}곡'
                    : '검색 ${workspace.filteredEntries.length}곡 / 전체 ${workspace.entries.length}곡',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ),
          Expanded(
            flex: 3,
            child: workspace.rootPath == null
                ? const Center(child: Text('작업 폴더를 선택하세요'))
                : ListView.builder(
                    itemCount: workspace.filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = workspace.filteredEntries[index];
                      return Draggable<SubFileEntry>(
                        data: entry,
                        feedback: Material(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(entry.listTitle),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.4,
                          child: SelectableItemCard(
                            selected: playback.currentPath == entry.path &&
                                playback.panelLayout ==
                                    SlidePanelLayout.singleSong,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              title: Text(entry.listTitle),
                            subtitle: Text(
                              entry.relativePath,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                            ),
                          ),
                        ),
                        child: SelectableItemCard(
                          selected: playback.currentPath == entry.path &&
                              playback.panelLayout ==
                                  SlidePanelLayout.singleSong,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            title: Text(entry.listTitle),
                            subtitle: Text(
                              entry.relativePath,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                            onTap: () => ref
                                .read(playbackProvider.notifier)
                                .loadSub(entry.path),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Text(
                  '예배 순서',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '새 순서',
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _createOrderDialog(context, ref),
                ),
              ],
            ),
          ),
          if (orderState.orders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String>(
                isExpanded: true,
                value: orderState.activeOrderId,
                hint: const Text('순서 선택'),
                items: orderState.orders
                    .map(
                      (o) => DropdownMenuItem(value: o.id, child: Text(o.name)),
                    )
                    .toList(),
                onChanged: (id) =>
                    ref.read(orderProvider.notifier).setActiveOrder(id),
              ),
            ),
          const Expanded(
            flex: 2,
            child: OperatorOrderList(),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrderDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: '주일예배');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('예배 순서 만들기'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('만들기'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(orderProvider.notifier).createOrder(name);
    }
  }
}
