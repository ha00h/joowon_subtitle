import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/color_utils.dart';

/// 프리셋 + HEX 입력 + HSV 색상 선택 다이얼로그
class ColorPickerRow extends StatefulWidget {
  const ColorPickerRow({
    required this.label,
    required this.color,
    required this.onChanged,
    this.supportsAlpha = false,
    super.key,
  });

  final String label;
  final String color;
  final ValueChanged<String> onChanged;
  final bool supportsAlpha;

  static const presetColors = [
    ('#FFFFFF', '흰색'),
    ('#FFF8E7', '크림'),
    ('#FFD700', '금색'),
    ('#FFA500', '주황'),
    ('#FF6B6B', '빨강'),
    ('#FF69B4', '분홍'),
    ('#E6B3FF', '연보라'),
    ('#9B59B6', '보라'),
    ('#87CEEB', '하늘'),
    ('#3498DB', '파랑'),
    ('#1E3A5F', '남색'),
    ('#2ECC71', '초록'),
    ('#98D8AA', '연두'),
    ('#C0C0C0', '은색'),
    ('#808080', '회색'),
    ('#000000', '검정'),
  ];

  @override
  State<ColorPickerRow> createState() => _ColorPickerRowState();
}

class _ColorPickerRowState extends State<ColorPickerRow> {
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: widget.color.toUpperCase());
  }

  @override
  void didUpdateWidget(covariant ColorPickerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color.toUpperCase() != widget.color.toUpperCase()) {
      _hexController.text = widget.color.toUpperCase();
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Future<void> _openPicker() async {
    final initial = tryParseHexColor(widget.color) ?? Colors.white;
    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => _HsvColorPickerDialog(
        initial: initial,
        supportsAlpha: widget.supportsAlpha,
      ),
    );
    if (result == null) return;
    final hex = colorToHex(result, withAlpha: widget.supportsAlpha);
    _hexController.text = hex;
    widget.onChanged(hex);
  }

  void _applyHexInput() {
    final normalized = normalizeHexColor(
      _hexController.text,
      allowAlpha: widget.supportsAlpha,
    );
    if (normalized == null) {
      _hexController.text = widget.color.toUpperCase();
      return;
    }
    _hexController.text = normalized;
    widget.onChanged(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final current = tryParseHexColor(widget.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ColorPickerRow.presetColors.map((preset) {
            final selected =
                widget.color.toUpperCase() == preset.$1.toUpperCase();
            return _SwatchButton(
              hex: preset.$1,
              tooltip: preset.$2,
              selected: selected,
              onTap: () {
                _hexController.text = preset.$1;
                widget.onChanged(preset.$1);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            InkWell(
              onTap: _openPicker,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: current ?? Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _hexController,
                decoration: const InputDecoration(
                  labelText: 'HEX',
                  hintText: '#FFFFFF',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[#0-9A-Fa-f]')),
                ],
                onSubmitted: (_) => _applyHexInput(),
                onEditingComplete: _applyHexInput,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: '색상 고르기',
              onPressed: _openPicker,
              icon: const Icon(Icons.colorize_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.hex,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: parseHexColor(hex),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              width: selected ? 2.5 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _HsvColorPickerDialog extends StatefulWidget {
  const _HsvColorPickerDialog({
    required this.initial,
    required this.supportsAlpha,
  });

  final Color initial;
  final bool supportsAlpha;

  @override
  State<_HsvColorPickerDialog> createState() => _HsvColorPickerDialogState();
}

class _HsvColorPickerDialogState extends State<_HsvColorPickerDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  Color get _color => _hsv.toColor();

  @override
  Widget build(BuildContext context) {
    final hex = colorToHex(_color, withAlpha: widget.supportsAlpha);

    return AlertDialog(
      title: const Text('색상 선택'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                hex,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: _hsv.value > 0.55 ? Colors.black87 : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SliderRow(
              label: '색상(H)',
              value: _hsv.hue,
              min: 0,
              max: 360,
              divisions: 360,
              activeColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
              onChanged: (v) => setState(() => _hsv = _hsv.withHue(v)),
            ),
            _SliderRow(
              label: '채도(S)',
              value: _hsv.saturation,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => _hsv = _hsv.withSaturation(v)),
            ),
            _SliderRow(
              label: '밝기(V)',
              value: _hsv.value,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => _hsv = _hsv.withValue(v)),
            ),
            if (widget.supportsAlpha)
              _SliderRow(
                label: '투명도',
                value: _hsv.alpha,
                min: 0,
                max: 1,
                onChanged: (v) => setState(() => _hsv = _hsv.withAlpha(v)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('적용'),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.activeColor,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final Color? activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// 다이얼로그만 필요할 때
Future<String?> pickHexColor(
  BuildContext context, {
  required String initialHex,
  bool supportsAlpha = false,
}) async {
  final initial = tryParseHexColor(initialHex) ?? Colors.white;
  final color = await showDialog<Color>(
    context: context,
    builder: (ctx) => _HsvColorPickerDialog(
      initial: initial,
      supportsAlpha: supportsAlpha,
    ),
  );
  if (color == null) return null;
  return colorToHex(color, withAlpha: supportsAlpha);
}
