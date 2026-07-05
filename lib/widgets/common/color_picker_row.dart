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
  late final TextEditingController _rController;
  late final TextEditingController _gController;
  late final TextEditingController _bController;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    final rgb = colorToRgb(widget.initial);
    _rController = TextEditingController(text: '${rgb.r}');
    _gController = TextEditingController(text: '${rgb.g}');
    _bController = TextEditingController(text: '${rgb.b}');
  }

  @override
  void dispose() {
    _rController.dispose();
    _gController.dispose();
    _bController.dispose();
    super.dispose();
  }

  Color get _color => _hsv.toColor();

  void _setColorFromHsv(HSVColor hsv) {
    setState(() => _hsv = hsv);
    final rgb = colorToRgb(hsv.toColor());
    _rController.text = '${rgb.r}';
    _gController.text = '${rgb.g}';
    _bController.text = '${rgb.b}';
  }

  void _setColorFromRgb(int r, int g, int b) {
    _setColorFromHsv(HSVColor.fromColor(colorFromRgb(r, g, b)));
  }

  void _applyRgbField() {
    final r = parseRgbChannel(_rController.text);
    final g = parseRgbChannel(_gController.text);
    final b = parseRgbChannel(_bController.text);
    if (r == null || g == null || b == null) {
      final rgb = colorToRgb(_color);
      _rController.text = '${rgb.r}';
      _gController.text = '${rgb.g}';
      _bController.text = '${rgb.b}';
      return;
    }
    _setColorFromRgb(r, g, b);
  }

  void _updateSvFromLocal(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final saturation = (local.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - local.dy / size.height).clamp(0.0, 1.0);
    _setColorFromHsv(_hsv.withSaturation(saturation).withValue(value));
  }

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
            LayoutBuilder(
              builder: (context, constraints) {
                const panelHeight = 160.0;
                final panelSize = Size(constraints.maxWidth, panelHeight);
                final knobX = _hsv.saturation * panelSize.width;
                final knobY = (1 - _hsv.value) * panelSize.height;
                return GestureDetector(
                  onPanDown: (d) => _updateSvFromLocal(d.localPosition, panelSize),
                  onPanUpdate: (d) =>
                      _updateSvFromLocal(d.localPosition, panelSize),
                  onTapDown: (d) => _updateSvFromLocal(d.localPosition, panelSize),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: panelSize.width,
                      height: panelSize.height,
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: panelSize,
                            painter: _SaturationValuePainter(hue: _hsv.hue),
                          ),
                          Positioned(
                            left: knobX.clamp(0, panelSize.width) - 8,
                            top: knobY.clamp(0, panelSize.height) - 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 2,
                                  ),
                                ],
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
            const SizedBox(height: 12),
            _HueSliderRow(
              value: _hsv.hue,
              onChanged: (v) => _setColorFromHsv(_hsv.withHue(v)),
            ),
            if (widget.supportsAlpha)
              _SliderRow(
                label: '투명도',
                value: _hsv.alpha,
                min: 0,
                max: 1,
                onChanged: (v) => _setColorFromHsv(_hsv.withAlpha(v)),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rController,
                    decoration: const InputDecoration(
                      labelText: 'R',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onSubmitted: (_) => _applyRgbField(),
                    onEditingComplete: _applyRgbField,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _gController,
                    decoration: const InputDecoration(
                      labelText: 'G',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onSubmitted: (_) => _applyRgbField(),
                    onEditingComplete: _applyRgbField,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _bController,
                    decoration: const InputDecoration(
                      labelText: 'B',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onSubmitted: (_) => _applyRgbField(),
                    onEditingComplete: _applyRgbField,
                  ),
                ),
              ],
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

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final base = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}

class _HueSliderRow extends StatelessWidget {
  const _HueSliderRow({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  static const _trackHeight = 16.0;
  static const _thumbRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    final thumbColor = HSVColor.fromAHSV(1, value, 1, 1).toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('색상(H)', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        SizedBox(
          height: _thumbRadius * 2 + 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _thumbRadius),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_trackHeight / 2),
                  child: SizedBox(
                    height: _trackHeight,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _HueTrackPainter(),
                    ),
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: _trackHeight,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: thumbColor,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: _thumbRadius,
                    elevation: 3,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: value.clamp(0, 360),
                  min: 0,
                  max: 360,
                  divisions: 360,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HueTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stops = 7;
    final colors = List<Color>.generate(
      stops + 1,
      (i) => HSVColor.fromAHSV(1, i * 360 / stops, 1, 1).toColor(),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(colors: colors).createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
