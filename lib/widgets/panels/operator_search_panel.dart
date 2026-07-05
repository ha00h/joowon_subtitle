import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../providers/order_provider.dart';
import '../../providers/playback_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../services/workspace_scanner.dart';
import '../common/always_visible_scrollbar.dart';
import '../common/panel_resize_handle.dart';
import 'operator_order_list.dart';
import 'operator_search_field.dart';
import 'selectable_item_card.dart';

class OperatorSearchPanel extends ConsumerStatefulWidget {
  const OperatorSearchPanel({super.key});

  @override
  ConsumerState<OperatorSearchPanel> createState() =>
      _OperatorSearchPanelState();
}

class _OperatorSearchPanelState extends ConsumerState<OperatorSearchPanel> {
  double? _dragListRatio;

  double _listRatio(AppSettings settings) =>
      _dragListRatio ?? settings.operatorSearchListRatio;

  Future<void> _persistListRatio(double ratio) async {
    await ref.read(settingsProvider.notifier).setOperatorSearchListRatio(ratio);
    if (mounted) setState(() => _dragListRatio = null);
  }

  Widget _buildSongEntry(
    BuildContext context,
    WidgetRef ref,
    SubFileEntry entry,
    PlaybackState playback,
  ) {
    final selected = playback.currentPath == entry.path &&
        playback.panelLayout == SlidePanelLayout.singleSong;

    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(entry.listTitle),
      onTap: () => ref.read(playbackProvider.notifier).loadSub(entry.path),
    );

    final card = GestureDetector(
      onSecondaryTapUp: (details) =>
          _showEntryContextMenu(context, ref, entry, details),
      child: SelectableItemCard(selected: selected, child: tile),
    );

    return Draggable<SubFileEntry>(
      data: entry,
      feedback: Material(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(entry.listTitle),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: card,
    );
  }

  void _showEntryContextMenu(
    BuildContext context,
    WidgetRef ref,
    SubFileEntry entry,
    TapUpDetails details,
  ) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(details.globalPosition, details.globalPosition),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(value: 'rename', child: Text('이름 변경')),
      ],
    ).then((value) {
      if (value == 'rename' && context.mounted) {
        unawaited(_renameEntry(context, ref, entry));
      }
    });
  }

  Future<void> _renameEntry(
    BuildContext context,
    WidgetRef ref,
    SubFileEntry entry,
  ) async {
    final controller = TextEditingController(
      text: p.basenameWithoutExtension(entry.relativePath),
    );
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('파일 이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '확장자 없이 입력',
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('변경'),
          ),
        ],
      ),
    );
    if (newName == null || newName.trim().isEmpty) return;

    try {
      await ref.read(workspaceProvider.notifier).renameSubFile(
            oldPath: entry.path,
            newBaseName: newName,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이름 변경 실패: $e')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    final orderState = ref.watch(orderProvider);
    final playback = ref.watch(playbackProvider);
    final settings = ref.watch(settingsProvider);
    final listRatio = _listRatio(settings);

    return ScrollConfiguration(
      behavior: const AlwaysVisibleScrollbarBehavior(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          final minListHeight =
              totalHeight * AppSettings.minOperatorSearchListRatio;
          final maxListHeight =
              totalHeight * AppSettings.maxOperatorSearchListRatio;
          final listHeight = (totalHeight * listRatio)
              .clamp(minListHeight, maxListHeight);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: OperatorSearchField(
                        initialValue: workspace.query,
                        onChanged:
                            ref.read(workspaceProvider.notifier).setQuery,
                      ),
                    ),
                    IconButton(
                      tooltip: '목록 새로고침',
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: workspace.rootPath != null
                          ? () =>
                              ref.read(workspaceProvider.notifier).rescan()
                          : null,
                    ),
                  ],
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
              SizedBox(
                height: listHeight,
                child: workspace.rootPath == null
                    ? const Center(child: Text('작업 폴더를 선택하세요'))
                    : ListView.builder(
                        itemCount: workspace.filteredEntries.length,
                        itemBuilder: (context, index) => _buildSongEntry(
                          context,
                          ref,
                          workspace.filteredEntries[index],
                          playback,
                        ),
                      ),
              ),
              PanelResizeHandle(
                axis: Axis.vertical,
                onDelta: (dy) {
                  if (totalHeight <= 0) return;
                  final next = ((listHeight + dy) / totalHeight).clamp(
                    AppSettings.minOperatorSearchListRatio,
                    AppSettings.maxOperatorSearchListRatio,
                  );
                  setState(() => _dragListRatio = next);
                },
                onDragEnd: () {
                  final ratio = _dragListRatio;
                  if (ratio == null) return;
                  unawaited(_persistListRatio(ratio));
                },
              ),
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
                          (o) => DropdownMenuItem(
                            value: o.id,
                            child: Text(o.name),
                          ),
                        )
                        .toList(),
                    onChanged: (id) =>
                        ref.read(orderProvider.notifier).setActiveOrder(id),
                  ),
                ),
              Expanded(
                child: const OperatorOrderList(),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void deactivate() {
    final ratio = _dragListRatio;
    if (ratio != null) {
      ref.read(settingsProvider.notifier).setOperatorSearchListRatio(ratio);
    }
    super.deactivate();
  }
}
