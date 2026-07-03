import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/resolved_text_style.dart';
import '../../models/slide_elements.dart';
import '../../models/style_file.dart';
import '../../models/sub_file.dart';
import '../../providers/style_provider.dart';
import '../../services/style_store.dart';
import '../../services/sub_io.dart';
import '../canvas/canvas_renderer.dart';
import '../common/aspect_ratio_fhd.dart';

class ImportPreviewResult {
  const ImportPreviewResult({required this.sub});

  final SubFile sub;
}

Future<ImportPreviewResult?> showImportPreviewDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String title,
  required String content,
}) {
  return showDialog<ImportPreviewResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ImportPreviewDialog(
      title: title,
      content: content,
      styleEntries: ref.read(styleProvider).catalog,
      initialStylePath: ref.read(styleProvider).activePath,
    ),
  );
}

class ImportPreviewDialog extends StatefulWidget {
  const ImportPreviewDialog({
    required this.title,
    required this.content,
    required this.styleEntries,
    this.initialStylePath,
    super.key,
  });

  final String title;
  final String content;
  final List<StyleEntry> styleEntries;
  final String? initialStylePath;

  @override
  State<ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<ImportPreviewDialog> {
  final _subIo = SubIo();

  late List<StyleEntry> _styleEntries;
  late StyleEntry _selectedStyle;
  late SubFile _previewSub;

  @override
  void initState() {
    super.initState();
    _styleEntries = widget.styleEntries;
    _selectedStyle = _findInitialStyle() ??
        (_styleEntries.isNotEmpty
            ? _styleEntries.first
            : StyleEntry(
                path: '',
                name: '기본',
                style: StyleFile.defaultStyle,
              ));
    _rebuildPreview();
  }

  StyleEntry? _findInitialStyle() {
    if (widget.initialStylePath == null) return null;
    for (final entry in _styleEntries) {
      if (entry.path == widget.initialStylePath) return entry;
    }
    return null;
  }

  void _rebuildPreview() {
    _previewSub = _subIo.fromTxt(
      content: widget.content,
      title: widget.title,
      style: _selectedStyle.style,
    );
  }

  void _onStyleChanged(StyleEntry? entry) {
    if (entry == null) return;
    setState(() {
      _selectedStyle = entry;
      _rebuildPreview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final resolver = StyleResolver(styleFile: _selectedStyle.style);
    final slides = _previewSub.slides;
    final hasSlides = slides.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Import 미리보기',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('스타일'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<StyleEntry>(
                      isExpanded: true,
                      value: _selectedStyle,
                      items: _styleEntries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                      onChanged: _onStyleChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: hasSlides
                      ? Scrollbar(
                          thumbVisibility: true,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 260,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 16 / 11,
                            ),
                            itemCount: slides.length,
                            itemBuilder: (context, index) {
                              return _PreviewSlideThumb(
                                slideNumber: index + 1,
                                slide: slides[index],
                                resolveText: resolver.resolveText,
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Text('가져올 텍스트가 없습니다'),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: hasSlides
                        ? () => Navigator.pop(
                              context,
                              ImportPreviewResult(sub: _previewSub),
                            )
                        : null,
                    child: const Text('Import'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewSlideThumb extends StatelessWidget {
  const _PreviewSlideThumb({
    required this.slideNumber,
    required this.slide,
    required this.resolveText,
  });

  final int slideNumber;
  final Slide slide;
  final ResolvedTextStyle Function(SlideElement) resolveText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '[$slideNumber]',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: ColoredBox(
                color: Colors.black,
                child: AspectRatio(
                  aspectRatio: AspectRatioFhd.aspectRatio,
                  child: CanvasRenderer(
                    elements: slide.elements,
                    resolveText: resolveText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
