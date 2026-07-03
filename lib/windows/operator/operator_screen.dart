import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/import_flow.dart';
import '../../services/workspace_picker.dart';

import '../../services/workspace_scanner.dart';
import '../../providers/output_window_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/playback_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/style_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/panels/operator_status_bar.dart';
import '../../widgets/panels/operator_toolbar.dart';
import '../../widgets/panels/slide_operator_panel.dart';
import 'settings_screen.dart';
import 'style_screen.dart';
import '../../widgets/editor/unified_editor_screen.dart';

class OperatorScreen extends ConsumerStatefulWidget {
  const OperatorScreen({super.key});

  @override
  ConsumerState<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends ConsumerState<OperatorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSettings());
  }

  Future<void> _restoreSettings() async {
    await ref.read(settingsProvider.notifier).restoreSecurityScopedAccess();
    ref.read(workspaceProvider.notifier).reloadFromSettings();

    await ref.read(styleProvider.notifier).initialize();

    final settings = ref.read(settingsProvider);
    final monitors = await ref.read(monitorsProvider.future);
    if (settings.outputMonitorId == null && monitors.monitors.isNotEmpty) {
      await ref
          .read(settingsProvider.notifier)
          .setOutputMonitorId(monitors.monitors.first.id);
    }

    if (monitors.isFallback && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('모니터 경고'),
            content: Text(
              monitors.error ??
                  '모니터 API를 사용할 수 없습니다. 더미 모니터 목록으로 UI를 표시합니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      });
    }

    if (!ref.read(outputWindowProvider).isOpen) {
      await ref.read(outputWindowProvider.notifier).openOutputWindow();
    }
  }

  Future<void> _toggleOutputWindow(WidgetRef ref) async {
    final notifier = ref.read(outputWindowProvider.notifier);
    if (ref.read(outputWindowProvider).isOpen) {
      await notifier.closeOutputWindow();
    } else {
      await notifier.openOutputWindow();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeStyleFileProvider, (_, __) {
      ref.read(outputWindowProvider.notifier).syncPlaybackIfOpen();
    });

    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: _buildActions(ref),
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 300, child: _SearchPanel()),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OperatorToolbar(
                        onToggleOutput: () => _toggleOutputWindow(ref),
                        onPickWorkspace: () => _pickWorkspaceFolder(ref),
                        onOpenSettings: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                        onImportFile: () => ref
                            .read(importFlowProvider)
                            .importFromFile(context, ref),
                        onImportClipboard: () => ref
                            .read(importFlowProvider)
                            .importFromClipboard(context, ref),
                        onOpenStyles: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StyleScreen(),
                          ),
                        ),
                        onOpenEditor: () {
                          ref
                              .read(playbackProvider.notifier)
                              .prepareForSlideEdit();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UnifiedEditorScreen(
                                mode: UnifiedEditorMode.slide,
                              ),
                            ),
                          );
                        },
                      ),
                      const Expanded(child: SlideOperatorPanel()),
                      const OperatorStatusBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _folderLabel(String? path) {
    if (path == null) return '작업 폴더';
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.isNotEmpty ? parts.last : '작업 폴더';
  }

  Future<void> _pickWorkspaceFolder(WidgetRef ref) async {
    try {
      final picked = await pickWorkspaceDirectory(
        initialDirectory: ref.read(settingsProvider).workspacePath,
      );
      if (picked == null) return;
      ref.read(workspaceProvider.notifier).setRootPath(picked.path);
      await ref.read(settingsProvider.notifier).setWorkspacePath(
            picked.path,
            bookmark: picked.bookmark,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('작업 폴더: ${_folderLabel(picked.path)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('폴더 선택 실패: $e')),
        );
      }
    }
  }
}

const _shortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.arrowDown): NextSlideIntent(),
  SingleActivator(LogicalKeyboardKey.arrowRight): NextSlideIntent(),
  SingleActivator(LogicalKeyboardKey.arrowUp): PreviousSlideIntent(),
  SingleActivator(LogicalKeyboardKey.arrowLeft): PreviousSlideIntent(),
  SingleActivator(LogicalKeyboardKey.space): NextSlideIntent(),
  SingleActivator(LogicalKeyboardKey.pageDown): NextSlideIntent(),
  SingleActivator(LogicalKeyboardKey.pageUp): PreviousSlideIntent(),
  SingleActivator(LogicalKeyboardKey.keyB): ToggleBlankIntent(),
  SingleActivator(LogicalKeyboardKey.home): GoHomeIntent(),
  SingleActivator(LogicalKeyboardKey.enter): CommitDigitIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter): CommitDigitIntent(),
  SingleActivator(LogicalKeyboardKey.digit1): DigitIntent('1'),
  SingleActivator(LogicalKeyboardKey.digit2): DigitIntent('2'),
  SingleActivator(LogicalKeyboardKey.digit3): DigitIntent('3'),
  SingleActivator(LogicalKeyboardKey.digit4): DigitIntent('4'),
  SingleActivator(LogicalKeyboardKey.digit5): DigitIntent('5'),
  SingleActivator(LogicalKeyboardKey.digit6): DigitIntent('6'),
  SingleActivator(LogicalKeyboardKey.digit7): DigitIntent('7'),
  SingleActivator(LogicalKeyboardKey.digit8): DigitIntent('8'),
  SingleActivator(LogicalKeyboardKey.digit9): DigitIntent('9'),
  SingleActivator(LogicalKeyboardKey.digit0): DigitIntent('0'),
};

Map<Type, Action<Intent>> _buildActions(WidgetRef ref) {
  final playback = ref.read(playbackProvider.notifier);
  return {
    NextSlideIntent: CallbackAction<NextSlideIntent>(
      onInvoke: (_) {
        playback.nextSlide();
        return null;
      },
    ),
    PreviousSlideIntent: CallbackAction<PreviousSlideIntent>(
      onInvoke: (_) {
        playback.previousSlide();
        return null;
      },
    ),
    ToggleBlankIntent: CallbackAction<ToggleBlankIntent>(
      onInvoke: (_) {
        playback.toggleBlank();
        return null;
      },
    ),
    GoHomeIntent: CallbackAction<GoHomeIntent>(
      onInvoke: (_) {
        playback.goHome();
        return null;
      },
    ),
    CommitDigitIntent: CallbackAction<CommitDigitIntent>(
      onInvoke: (_) {
        playback.commitDigitBuffer();
        return null;
      },
    ),
    DigitIntent: CallbackAction<DigitIntent>(
      onInvoke: (intent) {
        playback.appendDigit(intent.digit);
        return null;
      },
    ),
  };
}

class NextSlideIntent extends Intent {
  const NextSlideIntent();
}

class PreviousSlideIntent extends Intent {
  const PreviousSlideIntent();
}

class ToggleBlankIntent extends Intent {
  const ToggleBlankIntent();
}

class GoHomeIntent extends Intent {
  const GoHomeIntent();
}

class CommitDigitIntent extends Intent {
  const CommitDigitIntent();
}

class DigitIntent extends Intent {
  const DigitIntent(this.digit);
  final String digit;
}

class _AlwaysVisibleScrollbarBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      child: child,
    );
  }
}

class _SearchPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final orderState = ref.watch(orderProvider);
    final playback = ref.watch(playbackProvider);

    return ScrollConfiguration(
      behavior: _AlwaysVisibleScrollbarBehavior(),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: '찬양 검색',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: ref.read(workspaceProvider.notifier).setQuery,
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
                          child: Text(entry.title),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.4,
                        child: _SelectableItemCard(
                          selected: playback.currentPath == entry.path &&
                              playback.panelLayout ==
                                  SlidePanelLayout.singleSong,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            title: Text(entry.title),
                          ),
                        ),
                      ),
                      child: _SelectableItemCard(
                        selected: playback.currentPath == entry.path &&
                            playback.panelLayout ==
                                SlidePanelLayout.singleSong,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          title: Text(entry.title),
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
              const Text('예배 순서', style: TextStyle(fontWeight: FontWeight.bold)),
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
        Expanded(
          flex: 2,
          child: _OrderList(),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
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

class _OrderList extends ConsumerWidget {
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
            return _SelectableItemCard(
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

class _SelectableItemCard extends StatelessWidget {
  const _SelectableItemCard({
    required this.selected,
    required this.child,
    super.key,
  });

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
