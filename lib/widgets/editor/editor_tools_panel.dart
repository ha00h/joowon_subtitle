import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../constants/app_fonts.dart';
import '../../models/style_file.dart';
import '../common/color_picker_row.dart';

class EditorToolsPanel extends StatelessWidget {
  const EditorToolsPanel({
    required this.background,
    required this.textStyle,
    required this.onBackgroundChanged,
    required this.onTextStyleChanged,
    this.title = '편집 도구',
    this.showBackgroundSection = true,
    super.key,
  });

  final String title;
  final BackgroundConfig background;
  final TextStyleConfig textStyle;
  final ValueChanged<BackgroundConfig> onBackgroundChanged;
  final ValueChanged<TextStyleConfig> onTextStyleChanged;
  final bool showBackgroundSection;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (showBackgroundSection) ...[
              _SectionTitle(title: '배경 설정'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'black', label: Text('검정')),
                  ButtonSegment(value: 'color', label: Text('색상')),
                  ButtonSegment(value: 'image', label: Text('이미지')),
                ],
                selected: {background.type},
                onSelectionChanged: (value) {
                  onBackgroundChanged(background.copyWith(type: value.first));
                },
              ),
              if (background.type == 'color') ...[
                const SizedBox(height: 12),
                ColorPickerRow(
                  label: '배경 색',
                  color: background.color ?? '#000000',
                  onChanged: (c) =>
                      onBackgroundChanged(background.copyWith(color: c)),
                ),
              ],
              if (background.type == 'image') ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickBackgroundImage(onBackgroundChanged),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    background.imageData == null ? '이미지 선택' : '이미지 변경',
                  ),
                ),
                if (background.imageData != null)
                  TextButton(
                    onPressed: () => onBackgroundChanged(
                      background.copyWith(clearImage: true),
                    ),
                    child: const Text('이미지 제거'),
                  ),
              ],
              const SizedBox(height: 24),
            ],
            _SectionTitle(title: '폰트 설정'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: AppFonts.options
                      .map((e) => e.$1)
                      .contains(textStyle.fontFamily)
                  ? textStyle.fontFamily
                  : AppFonts.defaultFamily,
              decoration: const InputDecoration(
                labelText: '폰트',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: AppFonts.options
                  .map((f) => DropdownMenuItem(value: f.$1, child: Text(f.$2)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                onTextStyleChanged(textStyle.copyWith(fontFamily: v));
              },
            ),
            const SizedBox(height: 12),
            Text('크기: ${textStyle.fontSize.toInt()}'),
            Slider(
              value: textStyle.fontSize.clamp(24, 120),
              min: 24,
              max: 120,
              divisions: 48,
              label: textStyle.fontSize.toInt().toString(),
              onChanged: (v) =>
                  onTextStyleChanged(textStyle.copyWith(fontSize: v)),
            ),
            ColorPickerRow(
              label: '폰트 색',
              color: textStyle.color,
              onChanged: (c) => onTextStyleChanged(textStyle.copyWith(color: c)),
            ),
            const SizedBox(height: 12),
            _SectionTitle(title: '정렬'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'left',
                  icon: Icon(Icons.format_align_left),
                  label: Text('왼쪽'),
                ),
                ButtonSegment(
                  value: 'center',
                  icon: Icon(Icons.format_align_center),
                  label: Text('가운데'),
                ),
                ButtonSegment(
                  value: 'right',
                  icon: Icon(Icons.format_align_right),
                  label: Text('오른쪽'),
                ),
              ],
              selected: {textStyle.textAlign},
              onSelectionChanged: (value) {
                onTextStyleChanged(textStyle.copyWith(textAlign: value.first));
              },
            ),
            const SizedBox(height: 12),
            Text('테두리: ${textStyle.strokeWidth.toStringAsFixed(1)}'),
            Slider(
              value: textStyle.strokeWidth.clamp(0, 8),
              min: 0,
              max: 8,
              divisions: 16,
              onChanged: (v) =>
                  onTextStyleChanged(textStyle.copyWith(strokeWidth: v)),
            ),
            ColorPickerRow(
              label: '테두리 색',
              color: textStyle.strokeColor,
              onChanged: (c) =>
                  onTextStyleChanged(textStyle.copyWith(strokeColor: c)),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('그림자'),
              value: textStyle.shadow.enabled,
              onChanged: (v) => onTextStyleChanged(
                textStyle.copyWith(
                  shadow: textStyle.shadow.copyWith(enabled: v),
                ),
              ),
            ),
            if (textStyle.shadow.enabled) ...[
              Text('그림자 X: ${textStyle.shadow.offsetX.toStringAsFixed(0)}'),
              Slider(
                value: textStyle.shadow.offsetX.clamp(-20, 20),
                min: -20,
                max: 20,
                divisions: 40,
                onChanged: (v) => onTextStyleChanged(
                  textStyle.copyWith(
                    shadow: textStyle.shadow.copyWith(offsetX: v),
                  ),
                ),
              ),
              Text('그림자 Y: ${textStyle.shadow.offsetY.toStringAsFixed(0)}'),
              Slider(
                value: textStyle.shadow.offsetY.clamp(-20, 20),
                min: -20,
                max: 20,
                divisions: 40,
                onChanged: (v) => onTextStyleChanged(
                  textStyle.copyWith(
                    shadow: textStyle.shadow.copyWith(offsetY: v),
                  ),
                ),
              ),
              Text('그림자 크기: ${textStyle.shadow.blur.toStringAsFixed(0)}'),
              Slider(
                value: textStyle.shadow.blur.clamp(0, 24),
                min: 0,
                max: 24,
                divisions: 24,
                onChanged: (v) => onTextStyleChanged(
                  textStyle.copyWith(
                    shadow: textStyle.shadow.copyWith(blur: v),
                  ),
                ),
              ),
              ColorPickerRow(
                label: '그림자 색',
                color: textStyle.shadow.color,
                supportsAlpha: true,
                onChanged: (c) => onTextStyleChanged(
                  textStyle.copyWith(
                    shadow: textStyle.shadow.copyWith(color: c),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickBackgroundImage(
    ValueChanged<BackgroundConfig> onChanged,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
    onChanged(
      background.copyWith(
        type: 'image',
        imageData: base64Encode(bytes),
        mimeType: 'image/png',
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
