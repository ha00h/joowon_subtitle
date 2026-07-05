import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/resolved_text_style.dart';
import '../../models/slide_elements.dart';
import '../../models/style_file.dart';
import '../../providers/output_window_provider.dart';
import '../../providers/playback_provider.dart';
import '../../providers/style_provider.dart';
import '../../services/style_store.dart';
import '../../widgets/canvas/canvas_editor.dart';
import '../../widgets/canvas/canvas_renderer.dart';
import '../../widgets/common/aspect_ratio_fhd.dart';
import '../../widgets/editor/editor_tools_panel.dart';
import '../../widgets/editor/slide_style_apply_panel.dart';
import '../../widgets/editor/style_region_canvas.dart';

enum UnifiedEditorMode { style, slide }

class UnifiedEditorScreen extends ConsumerStatefulWidget {
  const UnifiedEditorScreen({
    required this.mode,
    super.key,
  });

  final UnifiedEditorMode mode;

  @override
  ConsumerState<UnifiedEditorScreen> createState() =>
      _UnifiedEditorScreenState();
}

class _UnifiedEditorScreenState extends ConsumerState<UnifiedEditorScreen> {
  StyleEntry? _editingStyle;
  StyleFile? _styleDraft;
  String? _selectedRegionId;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initStyleCatalog());
  }

  Future<void> _initStyleCatalog() async {
    await ref.read(styleProvider.notifier).initialize();
    if (!mounted) return;
    if (widget.mode == UnifiedEditorMode.style) {
      final catalog = ref.read(styleProvider).catalog;
      if (catalog.isEmpty) return;
      final activePath = ref.read(styleProvider).activePath;
      final entry = catalog.firstWhere(
        (e) => e.path == activePath,
        orElse: () => catalog.first,
      );
      _selectStyleEntry(entry);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectStyleEntry(StyleEntry entry) {
    setState(() {
      _editingStyle = entry;
      _styleDraft = entry.style;
      _selectedRegionId = entry.style.textRegions.first.id;
      _nameController.text = entry.style.name;
    });
  }

  void _updateStyleDraft(StyleFile style) {
    setState(() => _styleDraft = style);
  }

  void _updateRegion(TextRegionConfig region) {
    final draft = _styleDraft;
    if (draft == null) return;
    final regions = draft.textRegions
        .map((r) => r.id == region.id ? region : r)
        .toList();

    if (region.id == 'verseLabel') {
      _updateStyleDraft(
        draft.copyWith(
          textRegions: regions,
          verseLabel: draft.verseLabel.copyWith(
            defaultPosition: (x: region.x, y: region.y),
          ),
        ),
      );
      return;
    }

    final body = regions.firstWhere((r) => r.id == 'body', orElse: () => region);
    _updateStyleDraft(
      draft.copyWith(
        textRegions: regions,
        text: draft.text.copyWith(
          defaultPosition: (x: body.x, y: body.y),
        ),
      ),
    );
  }

  Future<void> _createStyle() async {
    final entry = await ref.read(styleProvider.notifier).createStyle();
    if (!mounted) return;
    _selectStyleEntry(entry);
  }

  Future<void> _saveStyle() async {
    final editing = _editingStyle;
    final draft = _styleDraft;
    if (editing == null || draft == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('스타일 이름을 입력하세요');
      return;
    }
    final style = draft.copyWith(name: name);
    await ref.read(styleProvider.notifier).saveStyle(editing.path, style);
    await ref.read(styleProvider.notifier).selectStyle(
          StyleEntry(path: editing.path, name: name, style: style),
        );
    ref.read(outputWindowProvider.notifier).syncPlaybackIfOpen();
    if (!mounted) return;
    setState(() {
      _editingStyle = StyleEntry(path: editing.path, name: name, style: style);
      _styleDraft = style;
    });
    _snack('저장했습니다');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isStyleMode = widget.mode == UnifiedEditorMode.style;

    return Scaffold(
      appBar: AppBar(
        title: Text(isStyleMode ? '스타일' : '편집'),
        actions: [
          if (isStyleMode) ...[
            TextButton.icon(
              onPressed: _createStyle,
              icon: const Icon(Icons.add),
              label: const Text('새 스타일'),
            ),
            TextButton(onPressed: _saveStyle, child: const Text('저장')),
          ] else ...[
            Consumer(
              builder: (context, ref, _) {
                final editor = ref.watch(editorProvider);
                return Row(
                  children: [
                    IconButton(
                      tooltip: '실행 취소',
                      onPressed: editor.canUndo
                          ? ref.read(playbackProvider.notifier).undo
                          : null,
                      icon: const Icon(Icons.undo),
                    ),
                    IconButton(
                      tooltip: '다시 실행',
                      onPressed: editor.canRedo
                          ? ref.read(playbackProvider.notifier).redo
                          : null,
                      icon: const Icon(Icons.redo),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 220,
            child: isStyleMode ? _buildStyleList() : _buildSlideList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: isStyleMode ? _buildStyleCanvas() : _buildSlideCanvas()),
          const VerticalDivider(width: 1),
          SizedBox(
            width: 300,
            child: isStyleMode ? _buildStyleTools() : _buildSlideTools(),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleList() {
    final styleState = ref.watch(styleProvider);
    final catalog = styleState.catalog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '스타일 이름',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '스타일 목록',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: catalog.length,
            itemBuilder: (context, index) {
              final entry = catalog[index];
              final isEditing = entry.path == _editingStyle?.path;
              return ListTile(
                dense: true,
                selected: isEditing,
                leading: Icon(
                  isEditing ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: isEditing
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(entry.name),
                onTap: () => _selectStyleEntry(entry),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlideList() {
    final playback = ref.watch(playbackProvider);
    final sub = playback.currentSub;
    if (sub == null) {
      return const Center(child: Text('곡이 없습니다'));
    }

    final styleFile = ref.watch(activeStyleFileProvider);
    final resolver = StyleResolver(styleFile: styleFile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            sub.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: sub.slides.length,
            itemBuilder: (context, index) {
              final selected = playback.slideIndex == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () =>
                      ref.read(playbackProvider.notifier).goToSlide(index),
                  borderRadius: BorderRadius.circular(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            '[${index + 1}]',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        AspectRatio(
                          aspectRatio: AspectRatioFhd.aspectRatio,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(7),
                            ),
                            child: CanvasRenderer(
                              elements: sub.slides[index].elements,
                              resolveText: resolver.resolveText,
                              background: styleFile.background,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStyleCanvas() {
    final draft = _styleDraft;
    if (draft == null) {
      return const Center(child: Text('스타일을 선택하세요'));
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StyleRegionCanvas(
          style: draft,
          selectedRegionId: _selectedRegionId,
          onRegionSelected: (id) => setState(() => _selectedRegionId = id),
          onRegionChanged: _updateRegion,
        ),
      ),
    );
  }

  Widget _buildSlideCanvas() {
    final playback = ref.watch(playbackProvider);
    final sub = playback.currentSub;
    if (sub == null || sub.slides.isEmpty) {
      return const Center(child: Text('편집할 슬라이드가 없습니다'));
    }

    final slideIdx = playback.slideIndex;
    if (slideIdx < 0) {
      return const Center(child: Text('슬라이드를 선택하세요'));
    }
    final slide = sub.slides[slideIdx];
    final styleFile = ref.watch(activeStyleFileProvider);
    final resolver = StyleResolver(styleFile: styleFile);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: AspectRatioFhd.aspectRatio,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CanvasEditor(
                key: ValueKey('editor-slide-$slideIdx'),
                elements: slide.elements,
                resolveText: resolver.resolveText,
                background: styleFile.background,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyleTools() {
    final draft = _styleDraft;
    if (draft == null) {
      return const Center(child: Text('스타일을 선택하세요'));
    }

    final regionId = _selectedRegionId ?? 'body';
    final isVerseLabel = regionId == 'verseLabel';
    final regionLabel = isVerseLabel ? '절 표기' : '본문';
    final textStyle = isVerseLabel ? draft.verseLabel : draft.text;

    return EditorToolsPanel(
      title: '스타일 도구 — $regionLabel',
      background: draft.background,
      textStyle: textStyle,
      onBackgroundChanged: (bg) =>
          _updateStyleDraft(draft.copyWith(background: bg)),
      onTextStyleChanged: (text) => _updateStyleDraft(
        isVerseLabel
            ? draft.copyWith(verseLabel: text)
            : draft.copyWith(text: text),
      ),
    );
  }

  Widget _buildSlideTools() {
    final playback = ref.watch(playbackProvider);
    final sub = playback.currentSub;
    final styleFile = ref.watch(activeStyleFileProvider);
    final selectedId = ref.watch(editorProvider).selectedElementId;

    if (sub == null) {
      return const Center(child: Text('곡이 없습니다'));
    }

    final slideIdx = playback.slideIndex;
    if (slideIdx < 0) {
      return const Center(child: Text('슬라이드를 선택하세요'));
    }

    final slide = sub.slides[slideIdx];
    SlideElement? selected;
    for (final el in slide.elements) {
      if (el.id == selectedId) {
        selected = el;
        break;
      }
    }

    final panelTextStyle = _textStyleForPanel(styleFile, selected);

    final hasVerseLabel = slideHasVerseLabel(slide.elements);
    final canEnableVerseLabel = verseLabelTextForSlide(
              slide: slide,
              allSlides: sub.slides,
              hymnNumber: sub.hymnNumber,
              slideIndex: slideIdx,
            ) !=
            null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SlideStyleApplyPanel(
          slideIndex: slideIdx,
          onApplied: () => _snack('스타일을 적용했습니다'),
        ),
        const Divider(height: 1),
        SwitchListTile(
          title: const Text('절 표기'),
          subtitle: Text(
            slide.tag ?? '슬라이드 태그 없음',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: hasVerseLabel,
          onChanged: canEnableVerseLabel || hasVerseLabel
              ? (enabled) {
                  ref
                      .read(playbackProvider.notifier)
                      .setSlideVerseLabel(slideIdx, enabled: enabled);
                }
              : null,
        ),
        const Divider(height: 1),
        if (selected != null && isTextLikeElement(selected.type)) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(playbackProvider.notifier).updateElement(
                      clearTextStyleOverrides(selected!),
                    );
                _snack('스타일 기본값으로 되돌렸습니다');
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('이 요소만 기본값으로'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: EditorToolsPanel(
            title: selected == null ? '슬라이드 도구' : '선택 요소',
            background: styleFile.background,
            textStyle: panelTextStyle,
            showBackgroundSection: selected == null,
            onBackgroundChanged: (bg) async {
              final path = ref.read(styleProvider).activePath;
              if (path == null) return;
              final updated = styleFile.copyWith(background: bg);
              await ref.read(styleProvider.notifier).saveStyle(path, updated);
              ref.read(outputWindowProvider.notifier).syncPlaybackIfOpen();
            },
            onTextStyleChanged: (textStyle) {
              if (selected == null || !isTextLikeElement(selected.type)) {
                return;
              }
              ref.read(playbackProvider.notifier).updateElement(
                    selected.copyWith(
                      fontFamily: textStyle.fontFamily,
                      fontSize: textStyle.fontSize,
                      fontWeight: textStyle.fontWeight,
                      color: textStyle.color,
                      textStrokeWidth: textStyle.strokeWidth,
                      textStrokeColor: textStyle.strokeColor,
                      shadowEnabled: textStyle.shadow.enabled,
                      shadowOffsetX: textStyle.shadow.offsetX,
                      shadowOffsetY: textStyle.shadow.offsetY,
                      shadowBlur: textStyle.shadow.blur,
                      shadowColor: textStyle.shadow.color,
                      textShadow: textStyle.shadow.toCssShadow(),
                      textAlign: textStyle.textAlign,
                    ),
                  );
            },
          ),
        ),
      ],
    );
  }

  TextStyleConfig _textStyleForPanel(
    StyleFile styleFile,
    SlideElement? element,
  ) {
    if (element == null) return styleFile.text;
    final resolver = StyleResolver(styleFile: styleFile);
    final resolved = resolver.resolveText(element);
    final base = element.type == SlideElementType.verseLabel
        ? styleFile.verseLabel
        : styleFile.text;
    return base.copyWith(
      fontFamily: resolved.fontFamily,
      fontSize: resolved.fontSize,
      fontWeight: resolved.fontWeight,
      color: resolved.color,
      strokeWidth: resolved.strokeWidth,
      strokeColor: resolved.strokeColor,
      shadow: resolved.shadow,
      textAlign: resolved.textAlign,
    );
  }
}
