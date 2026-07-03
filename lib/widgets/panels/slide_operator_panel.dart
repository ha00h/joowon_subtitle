import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/resolved_text_style.dart';
import '../../models/slide_elements.dart';
import '../../models/sub_file.dart';
import '../../providers/operator_ui_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/playback_provider.dart';
import '../../providers/style_provider.dart';
import '../../services/sub_io.dart';
import '../canvas/canvas_renderer.dart';
import '../common/aspect_ratio_fhd.dart';

/// 조작 화면 메인 영역 — 검색(단일 곡) / 예배 순서(전체 목록) 레이아웃
class SlideOperatorPanel extends ConsumerStatefulWidget {
  const SlideOperatorPanel({super.key});

  @override
  ConsumerState<SlideOperatorPanel> createState() => _SlideOperatorPanelState();
}

class _SlideOperatorPanelState extends ConsumerState<SlideOperatorPanel> {
  final _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackProvider);
    final orderState = ref.watch(orderProvider);
    final styleFile = ref.watch(activeStyleFileProvider);
    final resolver = StyleResolver(styleFile: styleFile);
    final subIo = ref.read(subIoProvider);
    final notifier = ref.read(playbackProvider.notifier);

    final sub = playback.currentSub;
    final gridColumns = ref.watch(operatorUiProvider).gridColumns;

    if (sub == null || sub.slides.isEmpty) {
      return const _EmptyState();
    }

    if (playback.panelLayout == SlidePanelLayout.orderSequence &&
        orderState.activeOrder != null) {
      return _OrderSequenceLayout(
        playback: playback,
        orderState: orderState,
        subIo: subIo,
        gridColumns: gridColumns,
        resolveText: resolver.resolveText,
        verticalController: _verticalScrollController,
        onSelectSlide: (itemIndex, slideIndex) {
          notifier.loadOrderItem(itemIndex, slideIndex: slideIndex);
        },
        onSlideAction: _SlideGridActions(notifier: notifier),
      );
    }

    return ScrollConfiguration(
      behavior: _AlwaysVisibleScrollbarBehavior(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: _SlideGrid(
          sub: sub,
          gridColumns: gridColumns,
          liveSlideIndex:
              playback.slideIndex >= 0 ? playback.slideIndex : null,
          resolveText: resolver.resolveText,
          onSelectSlide: notifier.goToSlide,
          onSlideAction: _SlideGridActions(notifier: notifier),
        ),
      ),
    );
  }
}

class _OrderSequenceLayout extends StatefulWidget {
  const _OrderSequenceLayout({
    required this.playback,
    required this.orderState,
    required this.subIo,
    required this.gridColumns,
    required this.resolveText,
    required this.verticalController,
    required this.onSelectSlide,
    required this.onSlideAction,
  });

  final PlaybackState playback;
  final OrderState orderState;
  final SubIo subIo;
  final int gridColumns;
  final ResolvedTextStyle Function(SlideElement) resolveText;
  final ScrollController verticalController;
  final void Function(int itemIndex, int slideIndex) onSelectSlide;
  final _SlideGridActions onSlideAction;

  @override
  State<_OrderSequenceLayout> createState() => _OrderSequenceLayoutState();
}

class _OrderSequenceLayoutState extends State<_OrderSequenceLayout> {
  Object? _lastScrollKey;

  @override
  Widget build(BuildContext context) {
    final order = widget.orderState.activeOrder!;
    final scrollKey = Object.hash(
      order.id,
      widget.playback.currentPath,
      widget.playback.slideIndex,
    );
    if (scrollKey != _lastScrollKey) {
      _lastScrollKey = scrollKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveSection(widget.orderState.activeItemIndex);
      });
    }

    return ScrollConfiguration(
      behavior: _AlwaysVisibleScrollbarBehavior(),
      child: ListView.separated(
        controller: widget.verticalController,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: order.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 24),
        itemBuilder: (context, itemIndex) {
          final item = order.items[itemIndex];
          final isActiveHymn = widget.playback.currentPath == item.filePath;
          SubFile sub;
          if (isActiveHymn && widget.playback.currentSub != null) {
            sub = widget.playback.currentSub!;
          } else {
            try {
              sub = widget.subIo.readFile(item.filePath);
            } catch (_) {
              return _HymnTitle(title: item.title, error: '파일을 읽을 수 없습니다');
            }
          }
          if (sub.slides.isEmpty) {
            return _HymnTitle(title: sub.title, error: '슬라이드 없음');
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sub.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              _SlideGrid(
                sub: sub,
                gridColumns: widget.gridColumns,
                liveSlideIndex: isActiveHymn && widget.playback.slideIndex >= 0
                    ? widget.playback.slideIndex
                    : null,
                resolveText: widget.resolveText,
                onSelectSlide: (slideIndex) =>
                    widget.onSelectSlide(itemIndex, slideIndex),
                onSlideAction: widget.onSlideAction,
              ),
            ],
          );
        },
      ),
    );
  }

  void _scrollToActiveSection(int itemIndex) {
    if (!widget.verticalController.hasClients) return;
    const sectionHeight = 280.0;
    final target = (itemIndex * sectionHeight)
        .clamp(0.0, widget.verticalController.position.maxScrollExtent);
    widget.verticalController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

class _HymnTitle extends StatelessWidget {
  const _HymnTitle({required this.title, this.error});

  final String title;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _SlideGrid extends StatelessWidget {
  const _SlideGrid({
    required this.sub,
    required this.gridColumns,
    required this.liveSlideIndex,
    required this.resolveText,
    required this.onSelectSlide,
    required this.onSlideAction,
  });

  final SubFile sub;
  final int gridColumns;
  final int? liveSlideIndex;
  final ResolvedTextStyle Function(SlideElement) resolveText;
  final ValueChanged<int> onSelectSlide;
  final _SlideGridActions onSlideAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossSpacing = 16.0;
        const mainSpacing = 20.0;
        final cellWidth = (constraints.maxWidth -
                (gridColumns - 1) * crossSpacing) /
            gridColumns;
        const labelHeight = 28.0;
        final thumbHeight = cellWidth / AspectRatioFhd.aspectRatio;
        final cellHeight = labelHeight + thumbHeight;
        final aspectRatio = cellWidth / cellHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridColumns,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: mainSpacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: sub.slides.length,
          itemBuilder: (context, index) {
            final slideNumber = index + 1;
            final slide = sub.slides[index];
            final isLive = liveSlideIndex == index;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatSlideLabel(slideNumber, slide.tag),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: isLive ? FontWeight.bold : FontWeight.w500,
                        color: isLive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: _SlideThumb(
                      slide: slide,
                      isLive: isLive,
                      resolveText: resolveText,
                      onTap: () => onSelectSlide(index),
                      onSecondaryTap: (details) => onSlideAction.showContextMenu(
                        context: context,
                        globalPosition: details.globalPosition,
                        slideIndex: index,
                        slide: slide,
                        onBeforeAction: () => onSelectSlide(index),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SlideThumb extends StatelessWidget {
  const _SlideThumb({
    required this.slide,
    required this.isLive,
    required this.resolveText,
    required this.onTap,
    required this.onSecondaryTap,
  });

  static const _outerPadding = 6.0;
  static const _borderWidth = 2.0;

  final Slide slide;
  final bool isLive;
  final ResolvedTextStyle Function(SlideElement) resolveText;
  final VoidCallback onTap;
  final void Function(TapDownDetails details) onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(_outerPadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isLive
              ? colorScheme.primaryContainer
              : colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLive
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: _borderWidth,
          ),
          boxShadow: isLive
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            elevation: isLive ? 2 : 0,
            child: InkWell(
              onTap: onTap,
              onSecondaryTapDown: onSecondaryTap,
              child: AspectRatio(
                aspectRatio: AspectRatioFhd.aspectRatio,
                child: ColoredBox(
                  color: Colors.black,
                  child: CanvasRenderer(
                    elements: slide.elements,
                    resolveText: resolveText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '왼쪽에서 찬양을 선택하세요',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
      ),
    );
  }
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

class _SlideGridActions {
  const _SlideGridActions({required this.notifier});

  final PlaybackNotifier notifier;

  Future<void> showContextMenu({
    required BuildContext context,
    required Offset globalPosition,
    required int slideIndex,
    required Slide slide,
    required VoidCallback onBeforeAction,
  }) async {
    onBeforeAction();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => _SlideContextMenu(
        position: globalPosition,
        onDuplicate: () {
          Navigator.pop(ctx);
          notifier.duplicateSlideAfter(slideIndex);
        },
        onQuickEdit: () async {
          Navigator.pop(ctx);
          await _showQuickEditDialog(context, slideIndex, slide);
        },
        onDelete: () {
          Navigator.pop(ctx);
          notifier.deleteSlideAt(slideIndex);
        },
        onSetTag: (tag) {
          Navigator.pop(ctx);
          notifier.setSlideTag(slideIndex, tag);
        },
      ),
    );
  }

  Future<void> _showQuickEditDialog(
    BuildContext context,
    int slideIndex,
    Slide slide,
  ) async {
    SlideElement? textEl;
    for (final el in slide.elements) {
      if (el.type == SlideElementType.text) {
        textEl = el;
        break;
      }
    }

    final controller = TextEditingController(
      text: textEl?.lines?.join('\n') ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('빠른 편집'),
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
    controller.dispose();
    if (result != null) {
      notifier.updateSlideTextAt(slideIndex, result.split('\n'));
    }
  }
}

class _SlideContextMenu extends StatefulWidget {
  const _SlideContextMenu({
    required this.position,
    required this.onDuplicate,
    required this.onQuickEdit,
    required this.onDelete,
    required this.onSetTag,
  });

  final Offset position;
  final VoidCallback onDuplicate;
  final VoidCallback onQuickEdit;
  final VoidCallback onDelete;
  final void Function(String? tag) onSetTag;

  @override
  State<_SlideContextMenu> createState() => _SlideContextMenuState();
}

class _SlideContextMenuState extends State<_SlideContextMenu> {
  static const _menuWidth = 168.0;
  static const _rowHeight = 36.0;
  static const _tagRowIndex = 3;

  bool _tagHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Positioned(
            left: widget.position.dx,
            top: widget.position.dy,
            child: GestureDetector(
              onTap: () {},
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: colorScheme.surfaceContainerHigh,
                child: SizedBox(
                  width: _menuWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ContextMenuAction(
                        label: '복사(복제)',
                        onSelected: widget.onDuplicate,
                      ),
                      _ContextMenuAction(
                        label: '빠른 편집',
                        onSelected: widget.onQuickEdit,
                      ),
                      _ContextMenuAction(
                        label: '삭제',
                        onSelected: widget.onDelete,
                      ),
                      MouseRegion(
                        onEnter: (_) => setState(() => _tagHovered = true),
                        onExit: (_) => setState(() => _tagHovered = false),
                        child: SizedBox(
                          height: _rowHeight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tag',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_tagHovered)
            Positioned(
              left: widget.position.dx + _menuWidth - 4,
              top: widget.position.dy + _tagRowIndex * _rowHeight,
              child: MouseRegion(
                onEnter: (_) => setState(() => _tagHovered = true),
                onExit: (_) => setState(() => _tagHovered = false),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surfaceContainerHigh,
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...kSlideTags.map(
                          (tag) => _ContextMenuAction(
                            label: tag,
                            onSelected: () => widget.onSetTag(tag),
                          ),
                        ),
                        const Divider(height: 1),
                        _ContextMenuAction(
                          label: '지우기',
                          onSelected: () => widget.onSetTag(null),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContextMenuAction extends StatelessWidget {
  const _ContextMenuAction({
    required this.label,
    required this.onSelected,
  });

  final String label;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}
